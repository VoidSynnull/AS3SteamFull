package game.scenes.carrot.sewer.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.scenes.carrot.sewer.components.Rat;
	import game.scenes.carrot.sewer.nodes.RatNode;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;

	public class RatSystem extends System
	{
		public function RatSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
			
		override public function update(time:Number):void
		{
			var node:RatNode = _nodes.head;
			var rat:Rat = node.rat;
						
			var hitDisplay:Display = node.display;
			if ( hitDisplay.displayObject.hitTestPoint( group.shellApi.offsetX( playerSpatial.x ), group.shellApi.offsetY( playerSpatial.y ), true ))
			{
				if( !rat.isHit )
				{
					//_scene.shellApi.soundManager.playLibrarySound( SoundManager.EFFECTS_PATH + RAT_HIT, .5 );
					AudioUtils.play( group, SoundManager.EFFECTS_PATH + RAT_HIT, .5 );
					rat.isHit = true;
				}
			}
			
			rat.timer++;
			if( rat.timer >= cooldown )
			{
				rat.isHit = false;
				rat.timer = 0;
			}
		}
		
		override public function addToEngine(engine:Engine):void
		{			
			_nodes = engine.getNodeList( RatNode );
			playerSpatial = group.shellApi.player.get( Spatial );
		}
		
		override public function removeFromEngine(engine:Engine):void
		{
			engine.releaseNodeList( RatNode );
			_nodes = null;
		}
		
		private var _nodes:NodeList;
		private var playerSpatial:Spatial;
		private var cooldown:int = 30;
		private const RAT_HIT:String = "rat_bite_01.mp3";
	}
}