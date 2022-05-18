package  {
	import flash.display.MovieClip;
	
	public class CourseBuilder extends MovieClip {
		
		private var _asset:MovieClip
		private var _scale:Number = 1
		
		public function CourseBuilder() {
			_asset = this["course"]
			var mc:MovieClip
			var s:String = "<xml>"
			
			for (var i:int = 0; i < _asset.numChildren ; i++) {
				mc = MovieClip( _asset.getChildAt(i))
				if (mc.name) {
					var x:Number = Math.round(mc.x) * _scale
					var y:Number = Math.round(mc.y) * _scale
					s += "\n<" + mc.name + ">";
					s += "<x>" + x + "</x>"
					s += "<y>" + y + "</y>"		
					s += "</" + mc.name + ">"
				}
			}
			s += "\n</xml>"
		}
		
	}
	
}
