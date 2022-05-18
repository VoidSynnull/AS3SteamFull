// Used by:
// Card 2700 using facial limited_tombquest_pharoh

package game.data.specialAbility.character
{
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.data.display.SharedBitmapData;
	
	import game.components.specialAbility.ObjectSwarmComponent;
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.SystemPriorities;
	import game.systems.specialAbility.character.ObjectSwarmSystem;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	/**
	 * Create swarm of swfs moving across ground of scene
	 * 
	 * required params:
	 * swfPath			String		Path to swf file
	 * 
	 * optional params:
	 * numObjects		Number		Number of objects (default is 1)
	 * offsetX			Number 		X offset (default is 0)
	 * offsetY			Number		Y offset (default is 0)
	 * time				Number		Time for animation (default is 5)
	 */
	public class ScreenSwarm extends SpecialAbility
	{				
		override public function activate( node:SpecialAbilityNode ):void
		{
			SceneUtil.lockInput(super.group, true);
			super.loadAsset(_swfPath, loadComplete);
		}	
		
		/**
		 * When swf has loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			var bitmapData:BitmapData = BitmapUtils.createBitmapData(clip);
			// Add the MovieClip to the group
			var data:SharedBitmapData;
			var objectEntity:Entity = new Entity();
			var quality:Number = 1;
			_objects = new Array();
			
			for(var i:Number=0;i<_numObjects;i++)
			{
				if(!data)
					data = BitmapUtils.createBitmapData(clip, quality);
				objectEntity = EntityUtils.createSpatialEntity(super.group,BitmapUtils.createBitmapSprite(clip, quality, null, true, 0, data), super.entity.get(Display).container);
				
				var xPos:Number = super.entity.get(Spatial).x;
				var yPos:Number = super.entity.get(Spatial).y;
				
				objectEntity.get(Spatial).x = xPos  + (500) + (_offsetX*i)
				objectEntity.get(Spatial).y= yPos + _offsetY;
				
				var swarm:ObjectSwarmComponent = new ObjectSwarmComponent();
				if((Math.floor(Math.random()*100+1)) > 50)
				{
					swarm.isJumper = true;
					swarm.speedY = -Math.floor(Math.random()*20+1);
					swarm.startingY = yPos;
				}
				
				objectEntity.add( swarm );
				_objects.push(objectEntity);
			}
			
			data = null;
			_swarmSystem = new ObjectSwarmSystem();
			super.group.addSystem( _swarmSystem, SystemPriorities.update );
			super.setActive(true);
			var timedEvent:TimedEvent = new TimedEvent( _time, 1, endSwarm);
			SceneUtil.addTimedEvent(super.group, timedEvent);
		}
		
		/**
		 * When swarm ends 
		 */
		private function endSwarm():void
		{
			// unlock input
			SceneUtil.lockInput( super.group, false );
			
			// remove entities
			for(var i:Number=0; i != _numObjects; i++)
			{
				super.group.removeEntity(_objects[i]);
			}
			_objects = null;
			
			// remove swarm system
			super.group.removeSystem(_swarmSystem);
			
			// make inactive
			super.setActive( false );
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _offsetX:Number = 0;
		public var _offsetY:Number = 0;
		public var _numObjects:Number  = 1;
		public var _time:Number = 5;
		
		private var _objects:Array = new Array();
		private var _swarmSystem:ObjectSwarmSystem;
	}
}