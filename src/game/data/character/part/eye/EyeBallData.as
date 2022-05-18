package game.data.character.part.eye
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	public class EyeBallData
	{	
		
		private var _eyeball:MovieClip;
		public function get eyeball():MovieClip		{ return _eyeball; }
		
		private var _pupil:MovieClip;
		public function get pupil():MovieClip		{ return _pupil; }
		
		private var _pupilCenter:Point;
		public function get pupilCenter():Point		{ return _pupilCenter; }

		private var _pupilRange:int;
		public function get pupilRange():int		{ return _pupilRange; }


		public function EyeBallData( eye:MovieClip = null )
		{
			if ( eye != null )
			{
				create( eye );
			}
		}
		
		public function create( eyeClip:MovieClip ):void
		{
			_eyeball 	= eyeClip.eyeball;
			_pupil 		= eyeClip.pupil;
			
			var pupilGuide:MovieClip = eyeClip.pupilGuide;
			if ( _pupilCenter == null )
			{
				_pupilCenter = new Point( pupilGuide.x, pupilGuide.y );
			}
			else
			{
				_pupilCenter.x = pupilGuide.x;
				_pupilCenter.y = pupilGuide.y;
			}
			_pupilRange = pupilGuide.width / 2;
			pupilGuide.visible = false;
		}
	}
}