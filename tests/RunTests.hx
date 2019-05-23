package ;

class RunTests {

  static function main() {
    new pushx.sinch.SinchSmsPusher('9fc346b8-19f7-4457-9afd-a87aa574de80', 'nuiP2B3/+kGijhbax6LD+A==')
      .single('+85298433441', {notification:{body:'Testing'}})
      .handle(function(o) trace(o));
  }
  
}