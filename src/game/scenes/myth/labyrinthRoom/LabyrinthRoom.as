package game.scenes.myth.labyrinthRoom
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.data.game.GameEvent;
	import game.particles.FlameCreator;
	import game.scenes.myth.shared.MythScene;
	import game.util.CharUtils;
	
	public class LabyrinthRoom extends MythScene
	{
		public function LabyrinthRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/labyrinthRoom/";
			
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
			
			if( super.shellApi.checkEvent( _events.COMPLETED_LABYRINTH ))
			{
				if( !super.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.MINOTAUR_RING ))
				{
					CharUtils.moveToTarget( player, 325, 524, false, askForRing );
				}
				else
				{
					var entity:Entity = super.getEntityById( "minotaur" );
					var spatial:Spatial = entity.get( Spatial );
					spatial.scaleX *= -1;
				}
			}
		}
		
		private function setupTorches():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, _hitContainer[ "flame1" ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var i:uint = 1;
			for( i = 1; i < 5; i ++ )
			{
				clip = super._hitContainer[ "flame" + i ];
				_flameCreator.createFlame( this, clip, true );
			}
		}
		
		private function askForRing( entity:Entity ):void
		{
			entity = super.getEntityById( "minotaur" );
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.sayCurrent();
		}
		
		private var _flameCreator:FlameCreator;
		private static const RANDOM:String =		"random";
	}
}