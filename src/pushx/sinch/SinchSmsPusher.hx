package pushx.sinch;

import haxe.Json;
import tink.http.Header;
import tink.http.Fetch.*;
import haxe.io.Bytes;
import haxe.crypto.Base64;

using tink.CoreApi;

class SinchSmsPusher<Data:{}> implements pushx.Pusher<Data> {
	
	var auth:HeaderField;
	var contentType:HeaderField;
	var toMessage:pushx.Payload<Data>->String;
	
	public function new(applicationKey, applicationSecret, ?toMessage) {
		auth = new HeaderField(AUTHORIZATION, 'Basic ${Base64.encode(Bytes.ofString('$applicationKey:$applicationSecret')).toString()}');
		contentType = new HeaderField(CONTENT_TYPE, 'application/json');
		this.toMessage = toMessage != null ? toMessage : _toMessage;
	}
	
	function _toMessage(payload:pushx.Payload<Data>) {
		return switch payload.notification {
			case null | {body: null}: '<empty>'; // TODO
			case {body: body}: body;
		}
	}
	
	public function single(id:String, payload:pushx.Payload<Data>):Promise<pushx.Result>
		return multiple([id], payload);
	
	public function multiple(ids:Array<String>, payload:pushx.Payload<Data>):Promise<pushx.Result> {
		var body:String = tink.Json.stringify({message: toMessage(payload)});
		var contentLength = new HeaderField(CONTENT_LENGTH, Std.string(body.length));
		return Future.ofMany([for(id in ids) 
			fetch('https://messagingapi.sinch.com/v1/sms/$id', {
				method: POST,
				headers: [auth, contentLength, contentType],
				body: body,
			}).all()
		])
			.map(function(outcomes) {
				var errors = [];
				for(i in 0...outcomes.length) {
					switch outcomes[i] {
						case Success(res):
							if(res.header.statusCode >= 400)
								errors.push({id: ids[i], type: pushx.Result.ErrorType.Others(Error.withData(500, 'Sinch Errored', {code: res.header.statusCode, message: res.body.toString()}))});
						case Failure(e):
							errors.push({id: ids[i], type: pushx.Result.ErrorType.Others(e)});
					}
				}
				return ({errors: errors}:pushx.Result);
			});
	}
	
	public function topic(topic:String, payload:pushx.Payload<Data>):Promise<pushx.Result> {
		throw 'Sending to topic is not supported by pushx_sinch';
	}
}
