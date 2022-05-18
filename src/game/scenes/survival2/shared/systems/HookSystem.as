package game.scenes.survival2.shared.systems
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.data.sound.SoundModifier;
	import game.scenes.survival2.shared.components.Hook;
	import game.scenes.survival2.shared.components.Hookable;
	import game.scenes.survival2.shared.nodes.HookNode;
	import game.scenes.survival2.shared.nodes.HookableNode;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	import org.osflash.signals.Signal;
	
	public class HookSystem extends System
	{
		private var _hooks:NodeList;
		private var _hookables:NodeList;
		public var onHookStart:Signal;
		
		public function HookSystem()
		{
			onHookStart = new Signal();
			this._defaultPriority = SystemPriorities.update;
		}
		
		override public function update(time:Number):void
		{
			for(var hookNode:HookNode = this._hooks.head; hookNode; hookNode = hookNode.next)
			{
				if(EntityUtils.sleeping(hookNode.entity)) continue;
				
				var hook:Hook 					= hookNode.hook;
				var spatial:Spatial 			= hookNode.spatial;
				var motion:Motion 				= hookNode.motion;
				var hookDisplay:DisplayObject 	= hookNode.display.displayObject;
				
				// update start of line (end of pole)
				updateLineStartPosition( hookNode );
				
				// if extended to end of line, halt motion
				if(spatial.y > hook.line.y + hook.lineLength)
				{
					spatial.y = hook.line.y + hook.lineLength;
					motion.velocity.y = 0;
				}
				
				// if hook is dangling (below line start) then have it move towards center
				if(spatial.y > hook.line.y)
				{
					if(Math.abs(spatial.x - hook.line.x) > 10)
					{
						if(spatial.x > hook.line.x)
						{
							motion.velocity.x = -50;
						}
						else
						{
							motion.velocity.x = 50;
						}
					}
				}
				
				// check if hook has collider with a platform
				if( hookNode.platformCollider.isHit )
				{
					motion.zeroMotion();	// zero motion
					spatial.y -= 1;			// move off of platform to escape PlatformHitSystem zeroing velocity
					hook.state = hook.REELING_STATE;
				}

				// update hook state
				switch(hook.state)
				{
					case hook.START_STATE:
						hook.state = hook.FALLING_STATE;
						AudioUtils.play(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_out_01_loop.mp3", 1, true, [SoundModifier.EFFECTS]);
						spatial.x = hook.lineStart.x;
						spatial.y = hook.lineStart.y;
						hookNode.display.visible = true;
						hook.line.visible = true;
						this.onHookStart.dispatch();
						// dispatch event, notifying scene that fishing has started
						break;
					
					case hook.FALLING_STATE:
						if(spatial.y >= hook.line.y + hook.lineLength)
						{
  							hook.state = hook.HANGING_STATE;
							AudioUtils.stop(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_out_01_loop.mp3");
						}
						break;
					
					case hook.HANGING_STATE:
						break;
					   
					case hook.REELING_STATE:
						motion.velocity.y = hook.reelingVelocity;
						
						if( hook.hooked )
						{
							if(spatial.y < hook.line.y + hook.hookedMinY)	// if hook has hooked, and has reached pole
							{
								hook.state = hook.REELED_STATE;
								AudioUtils.stop(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_in_01_loop.mp3");
								motion.zeroMotion();
							}
						}
						else if(spatial.y < hook.line.y)					// if hook is not hooked, and has reached pole
						{
							hook.state = hook.REELED_STATE;
							AudioUtils.stop(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_in_01_loop.mp3");
							motion.zeroMotion();
							hook.remove = true;	// At this point we want to destroy the hook, the special abiltiy it is associated with removes the Entity and deactivates itself
						}
						break;
					
					case hook.REELED_STATE:
						break;
				}
				
				// draw line
				hook.line.graphics.clear();
				hook.line.graphics.lineStyle(1, 0xFFFFFF);
				hook.line.graphics.lineTo(spatial.x - hook.line.x, spatial.y - hook.line.y);
				hook.line.graphics.endFill();
				
				updateHookable( hookNode );
			}
		}
		
		private function updateHookable( hookNode:HookNode ):void
		{
			var hook:Hook 					= hookNode.hook;
			var hookDisplay:DisplayObject 	= hookNode.display.displayObject;
			
			// check against Entities with Hookable components
			for(var hookableNode:HookableNode = this._hookables.head; hookableNode; hookableNode = hookableNode.next)
			{
				if(EntityUtils.sleeping(hookableNode.entity)) continue;
				
				var hookable:Hookable = hookableNode.hookable;
				
				switch(hookable.state)
				{
					case hookable.IDLE_STATE:
						
						var hookableDisplay:MovieClip = hookableNode.display.displayObject as MovieClip;
						if( !hook.hooked && hookDisplay.hitTestObject(hookableDisplay))	// TODO :: want to test against mouthHit
						{
							/*
							Hookables look for a specific type of bait OR "any" bait if it doesn't matter.
							*/
							if(hook.bait == hookable.bait || hookable.bait == "any")
							{
								hookable.state = hookable.REELING_STATE;
								hookable.reeling.dispatch(hookableNode.entity, hookNode.entity);
								
								hook.state = hook.REELING_STATE;
								hook.hooked = true;
								AudioUtils.stop(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_out_01_loop.mp3");
								AudioUtils.play(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_in_01_loop.mp3", 1, true, [SoundModifier.EFFECTS]);
								AudioUtils.play(this.group, SoundManager.EFFECTS_PATH + "put_misc_item_down_01.mp3", 1, false, [SoundModifier.EFFECTS]);
								
								DisplayUtils.moveToOverUnder( hookDisplay, hookableDisplay, false );	// move hook behind hookable
							}
							else if( !hookable._hitHook )
							{
								hookable.wrongBait.dispatch(hookableNode.entity, hookNode.entity);
							}
							hookable._hitHook = true;
							
						}
						else
						{
							hookable._hitHook = false;
						}
						break;
					
					case hookable.REELING_STATE:
						
						hookableNode.spatial.x = hookNode.spatial.x + hookable.offsetX;
						hookableNode.spatial.y = hookNode.spatial.y + hookable.offsetY;
						
						if(hook.state == hook.REELED_STATE)
						{
							hookable.state = hookable.REELED_STATE;
							hookable.reeled.dispatch(hookableNode.entity, hookNode.entity);
						}
						
						break;
					
					case hookable.REELED_STATE:
						
						if(hookable.remove)
						{
							this.group.removeEntity(hookableNode.entity, true);
							hook.remove = true;	// Special Ability (Fishing) handles removal of hook Entity and ability deactivation
						}
						break;
				}
			}
		}
		
		/**
		 * Determines position of line start, which is at the end of fishing pole. 
		 * @param hookNode
		 * 
		 */
		private function updateLineStartPosition( hookNode:HookNode ):void
		{
			var hookC:Hook = hookNode.hook;
			var partDisplay:MovieClip = CharUtils.getPart(hookNode.parent.parent, CharUtils.ITEM).get(Display).displayObject as MovieClip;
			var playerDisplay:DisplayObject = hookNode.parent.parent.get(Display).displayObject;
			var point:Point = DisplayUtils.localToLocal(partDisplay, playerDisplay.parent);

			var lineStart:MovieClip = partDisplay.lineStart;
			var lineStartX:int = lineStart.x;
			var lineStartY:int = lineStart.y;
			var radians:Number = GeomUtils.degreeToRadian(partDisplay.rotation);
		
			var offsetX:Number;
			var offsetY:Number;
			if( hookNode.parent.parent.get(Spatial).scaleX < 0)
			{
				hookC.line.x = hookC.lineStart.x = point.x - Math.cos((radians + hookC.poleRotation) * -1) * hookC.poleDistance;
				hookC.line.y = hookC.lineStart.y = point.y - Math.sin((radians + hookC.poleRotation) * -1) * hookC.poleDistance;
			}
			else
			{
				hookC.line.x = hookC.lineStart.x = point.x + Math.cos(radians + hookC.poleRotation) * hookC.poleDistance;
				hookC.line.y = hookC.lineStart.y = point.y + Math.sin(radians + hookC.poleRotation) * hookC.poleDistance;
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this._hooks 	= systemManager.getNodeList(HookNode);
			this._hookables = systemManager.getNodeList(HookableNode);
			
			this._hooks.nodeRemoved.add(hookNodeRemoved);
		}
		
		private function hookNodeRemoved(node:HookNode):void
		{
			AudioUtils.stop(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_out_01_loop.mp3");
			AudioUtils.stop(this.group, SoundManager.EFFECTS_PATH + "fish_rod_reel_in_01_loop.mp3");

			for(var hookableNode:HookableNode = this._hookables.head; hookableNode; hookableNode = hookableNode.next)
			{
				hookableNode.hookable.state = hookableNode.hookable.IDLE_STATE;
				/*
				if(hookableNode.hookable.hooks[node.entity])
				{
					hookableNode.hookable.state = hookableNode.hookable.IDLE_STATE;
					delete hookableNode.hookable.hooks[node.entity];
					hookableNode.hookable.dropped.dispatch(hookableNode.entity, node.entity);
				}
				*/
			}
			
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(HookNode);
			systemManager.releaseNodeList(HookableNode);
			
			this._hooks 	= null;
			this._hookables = null;
		}
	}
}

