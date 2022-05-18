package game.scenes.myth.hadesThrone
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.particles.FlameCreator;
	import game.scenes.myth.shared.MythScene;
	
	public class HadesThrone extends MythScene
	{
		public function HadesThrone()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/hadesThrone/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			setupTorches();
			
		}
		
		/*******************************
		 * 			FLAMES
		 *******************************/

		private function setupTorches():void
		{ 
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "flame1" ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			for( i = 1; i < 8; i ++ )
			{
				clip = super._hitContainer[ "flame" + i ];
				_flameCreator.createFlame( this, clip, true );
			}
		}
		
		private var _flameCreator:FlameCreator;
	}
}