package game.scenes.myth.poseidonWater.systems
{	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.data.scene.characterDialog.DialogData;
	import game.scenes.myth.MythEvents;
	import game.scenes.myth.poseidonWater.PoseidonWater;
	import game.scenes.myth.poseidonWater.components.AirBubble;
	import game.scenes.myth.poseidonWater.nodes.AirBubbleNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	
	public class AirBubbleSystem extends GameSystem
	{
		public function AirBubbleSystem()
		{
			super( AirBubbleNode, nodeUpdate, nodeAdded );
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{			
			playerDialog = group.shellApi.player.get(Dialog);
			playerSpatial = group.shellApi.player.get( Spatial );
			_events = group.shellApi.islandEvents as MythEvents;
			
			meter = group.getEntityById( "oxygenMeter" );
			var offset:SpatialOffset = new SpatialOffset(group.shellApi.viewportWidth / 7,group.shellApi.viewportHeight / 1.15);
			meter.add(offset);
			
			var display:DisplayObjectContainer = EntityUtils.getDisplayObject(meter);
			bar = display.getChildByName( "oxygenBar" );
			bar.scaleX = oxygenLevel;
			super.addToEngine( systemManager );
		}
		
		private function nodeAdded( node:AirBubbleNode ):void
		{
			var bubble:AirBubble = node.airBubble;
			
			//bubble.hitZone.entered.add( Command.create( collectBubble, node ));
			bubble.hitZone.inside.add( Command.create( collectBubble, node ));
		}
		override public function update(time:Number):void{
			expendAir(time);
			super.update(time);
		}
		
		public function nodeUpdate(node:AirBubbleNode, time:Number):void
		{
			var bubble:AirBubble = node.airBubble;
			
			if( playerSpatial.x > 1600 && playerSpatial.y > 1600 )
			{
				if( !group.shellApi.checkEvent( _events.SAW_POSEIDON_BLOCK ))
				{
					group.shellApi.triggerEvent( _events.SAW_POSEIDON_BLOCK, true );
				}
			}
			
			switch( bubble.state )
			{
				case bubble.AWAKE:
					break;
				case bubble.FALL_ASLEEP:
					bubble.counter = 0;
					bubble.state = bubble.SLEEP;
					break;
				case bubble.SLEEP:
					bubble.counter++;
					if( bubble.counter > bubble.timer )
					{
						respawnBubble( node );
						bubble.state = bubble.AWAKE;
					}
					break;
			}
		}
		
		public function collectBubble( zoneId:String, characterId:String, node:AirBubbleNode ):void
		{
			var bubble:AirBubble = node.airBubble;
			var display:Display = node.display;
			
			display.visible = false;
		
			setSleep( bubble.hitSleep, true );
			bubble.state = bubble.FALL_ASLEEP;
			
			grabbedBubble();
		}

		private function respawnBubble( node:AirBubbleNode ):void
		{
			var bubble:AirBubble = node.airBubble;
			var display:Display = node.display;
			
			display.visible = true;
			
			setSleep( bubble.hitSleep, false );
		}
		
		private function setSleep( sleep:Sleep, sleeping:Boolean ):void
		{
			sleep.sleeping = sleeping;
			sleep.ignoreOffscreenSleep = sleeping;
			//sleep.ignoreGroupPause = sleeping;
		}

		public function grabbedBubble():void
		{
			oxygenLevel = oxygenMax;
			group.shellApi.triggerEvent("got_air_bubble");
		}
		
		public function expendAir(time:Number):void
		{
			if(!group.paused && draining){
				if(oxygenLevel > 0){
					oxygenLevel -= time * oxygenUsage;
					outOfAir = false;
				}
				else 
				{
					if( !outOfAir )
					{
						oxygenLevel = 0;				
						playerDialog.complete.addOnce(drownReset);
						playerDialog.sayById("player_drown");
						outOfAir = true;
						group.shellApi.triggerEvent("got_air_bubble");
					}
				}
				bar.scaleX = oxygenLevel;
			}
		}
		
		
		public function drownReset( characterDialog:DialogData ):void
		{
			if( outOfAir )
			{
				group.shellApi.loadScene( PoseidonWater );
			}
		}
		
		private var _events:MythEvents;
		private var outOfAir:Boolean = false;
		
		private var playerDialog:Dialog;
		private var playerSpatial:Spatial;
		
		private var oxygenLevel:Number = 1;
		private var oxygenMax:Number = 1;
		private var oxygenUsage:Number = 0.05; //0.0006;
		private var meter:Entity;
		private var bar:DisplayObject;
		
		public var draining:Boolean = true;
	}
}