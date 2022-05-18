package game.scenes.virusHunter.mouth.systems
{
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Display;
	import game.components.hit.EntityIdList;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.Platform;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.managers.EntityPool;
	import game.scenes.virusHunter.mouth.components.Bubble;
	import game.scenes.virusHunter.mouth.nodes.BubbleNode;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	
	public class BubbleSystem extends ListIteratingSystem
	{
		public function BubbleSystem( group:Group, pool:EntityPool, total:Dictionary )
		{
			super( BubbleNode, updateNode );
			_group = group;
			_pool = pool;
			_total = total;
		}
		
		private function updateNode( node:BubbleNode, time:Number ):void
		{
			var bubbleComp:Bubble = node.bubble;
			
			if( !bubbleComp.init )
			{
				initBubble( node );
			}
			
			else
			{
				var platform:Platform = bubbleComp.platform.get( Platform );
				var entityIdList:EntityIdList = bubbleComp.platform.get( EntityIdList );
				var spatial:Spatial = node.spatial;
				var display:Display = node.display;
				var motion:Motion = node.motion;
				var creator:HitCreator = new HitCreator();

				if( !bubbleComp.popping )
				{				 	
					if( platform )
					{
						if( spatial.y < MAX_HEIGHT )
						{
							bubbleComp.popping = true;
							popBubble( node );
						}
						
						else if( entityIdList.entities.length > 0 ) 
						{
							var player:Entity = _group.shellApi.player;
							var playerMotion:Motion = player.get( Motion );
							
							if( bubbleComp.firstLand )
							{
								playerMotion.velocity.y = -25;
								bubbleComp.firstLand = false;
							}
							
							if( bubbleComp.playSound )
							{
								AudioUtils.play(_group, SoundManager.EFFECTS_PATH + LAND_EFFECT, .8);
								bubbleComp.playSound = false;
							}
							
							else 
							{
								if( motion.velocity.y < MIN_SPEED )
								{
									motion.velocity.y += DAMPENING;
								}
							}
						}
					
					
						else
						{
							if( motion.velocity.y > MAX_SPEED )
							{
								motion.velocity.y -= DAMPENING;
							}
							
							bubbleComp.playSound = true;
							bubbleComp.cooldown = false;
						}
					}
				}
			}
		}
		
		private function initBubble( node:BubbleNode ):void
		{
			var bubbleComp:Bubble = node.bubble;
	
			var motion:Motion = node.motion;
			var timeline:Timeline;
			var sleep:Sleep;
			
			var startX:Number = START_X + ( Math.random() * X_RANDOMIZER ) - X_EQUALIZER;
			
			EntityUtils.position( node.entity, startX, START_Y );
			
			EntityUtils.position( bubbleComp.platform, startX, START_Y );
			Display( bubbleComp.platform.get( Display )).visible = false;
			
			if( !bubbleComp.recycled )
			{
				node.entity.add( new Id( "bubble" ));
			
				bubbleComp.platform.add( motion );
				Platform( bubbleComp.platform.get( Platform )).top = true;
			// separate blinks
				bubbleComp.float = TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( node.entity )).content.bubble, _group );
				timeline = bubbleComp.float.get( Timeline );
				timeline.labelReached.add( Command.create( timelineListener, bubbleComp.float ));
				
				bubbleComp.blink = TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( node.entity )).content.blink, _group );
				timeline = bubbleComp.blink.get( Timeline );
				timeline.labelReached.add(  Command.create( timelineListener, bubbleComp.blink ));	
			}
		
			else
			{
				sleep = node.bubble.platform.get(Sleep);
				sleep.sleeping = false;
				
				sleep = node.entity.get( Sleep );
				sleep.sleeping = false;
				
				bubbleComp.cooldown = false;
				bubbleComp.popping = false;
				bubbleComp.firstLand = true;
				bubbleComp.playSound = true;
				
			 	timeline = bubbleComp.float.get( Timeline );
				timeline.paused = false;
				timeline.gotoAndPlay( "spin" );
				
				timeline = bubbleComp.blink.get( Timeline );
				timeline.paused = false;
				timeline.gotoAndPlay( "spin" );
			}
			
			MovieClip( MovieClip( EntityUtils.getDisplayObject( node.entity )).content.blink ).visible = false;
				
			motion.velocity.y = START_SPEED + ( Math.random() * ( MAX_SPEED - START_SPEED ));
			
			bubbleComp.init = true;
			bubbleComp.recycled = false;
		}
		
		private function timelineListener( label:String, entity:Entity ):void 
		{
			var timeline:Timeline = entity.get( Timeline );
			
			switch( label )
			{
				case "endSpin":
					timeline.gotoAndPlay( "spin" );
					break;
				case "endPop":
					timeline.paused = true;
					break;	
			}
		}

		private function popBubble( node:BubbleNode ):void
		{
			var sleep:Sleep = node.bubble.platform.get(Sleep);
			sleep.sleeping = true;
			node.entity.ignoreGroupPause = true;
			
			if( _pool.release( node.bubble.platform, "platform" ))
			{
				_total[ "platform" ]--;			
			}
		
			MovieClip( MovieClip( EntityUtils.getDisplayObject( node.entity )).content.blink ).visible = true;
			
			var timeline:Timeline = node.bubble.blink.get( Timeline );
			timeline.gotoAndPlay( "pop" );
			
			timeline = node.bubble.float.get( Timeline );
			timeline.gotoAndPlay( "pop" );
			
			var number:int = Math.abs( Math.random() + 1 );
			if( number == 1 )
			{
				AudioUtils.play(_group, SoundManager.EFFECTS_PATH + POP_EFFECT_1, .5);
			}
			else
			{
				AudioUtils.play(_group, SoundManager.EFFECTS_PATH + POP_EFFECT_2, .5);
			}
			
			SceneUtil.addTimedEvent( _group, new TimedEvent( 1, 1, Command.create( releaseNode, node )));
		}
		
		private function releaseNode( node:BubbleNode ):void
		{
			var sleep:Sleep = node.entity.get(Sleep);
			sleep.sleeping = true;
			node.entity.ignoreGroupPause = true;
			
			if( _pool.release( node.entity, "bubble" ))
			{
				_total[ "bubble" ]--;
			}
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( BubbleNode );
			super.removeFromEngine( systemManager );
		}
		
		private var _group:Group;
		private var _pool:EntityPool;
		private var _total:Dictionary;
		
		private const POP_EFFECT_1:String = "pop_04.mp3";
		private const POP_EFFECT_2:String = "pop_05.mp3";
		private const LAND_EFFECT:String  = "ls_hollow_object_01.mp3";
		private const MAX_HEIGHT:uint = 1750;
		private const X_RANDOMIZER:uint = 420;
		private const X_EQUALIZER:uint = 250;
		private const Y_EQUALIZER:uint = 65;//65;
		
		private const START_SPEED:int = -100;
		private const MAX_SPEED:int = -130;//-250;
		private const MIN_SPEED:int = -50;//-150;
		private const DAMPENING:int = 1;
		
		private const START_X:Number = 650;
		private const START_Y:Number = 4000;
	}
}