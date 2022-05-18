package game.util
{
	import flash.display.FrameLabel;
	import flash.display.MovieClip;

	public class MovieClipUtils
	{
		public function MovieClipUtils()
		{
		}
		
		public static function hasLabel(movieClip:MovieClip, labelName:String):Boolean 
		{
			var i:int;
			var k:int = movieClip.currentLabels.length;
			var label:FrameLabel;
			for (i; i < k; ++i) {
				label = movieClip.currentLabels[i];
				if (label.name == labelName)
					return true;   
			}
			return false;
		}
	}
}