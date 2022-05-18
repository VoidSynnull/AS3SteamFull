package game.systems.actionChain.actions
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterWander;
	import game.components.timeline.Timeline;
	import game.creators.entity.character.CharacterCreator;
	import game.data.TimedEvent;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Stand;
	import game.data.character.CharacterData;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	// Play or stop at a frame in an avatar part timeline
	public class SkinFrameHitBoxAction extends ActionCommand 
	{
		private var partType:String;
		private var startFrame:*;
		private var mode:String;
		private var endLabel:*;
		private var childName:String;
		private var action:String;
		private var knockBack:Number;
		private var moveNPCBack:Boolean;
		private var hSpeed:Number;
		private var spin:Number;
		private var spinFriction:Number;
		private var delay:Number;
		
		private var _callback:Function;
		private var _hitBox:MovieClip;
		private var _group:Group;
		private var _hitNPC:Boolean = false;
		private var _dir:Number=1;
		
		/**
		 * Play or stop at a frame in an avatar part timeline
		 * @param char			Entity whose part timeline will be played
		 * @param partType		Name of part type
		 * @param startFrame	Frame label to start at
		 * @param action        action to execute when collided with npc
		 * @param knockback     knockback amount
		 * @param childName		Name of child clip whose timeline will be played
		 * @param mode			Play mode (play, stop, gotoAndPlay, gotoAndStop)
		 * @param endLabel		Frame label to stop at - if no end label given, then it completes on the last frame
		 */
		public function SkinFrameHitBoxAction( char:Entity, partType:String, startFrame:*, action:String, knockBack:Number=0, 
											   hSpeed:Number=0,spin:Number=0, spinFriction:Number=0, delay:Number=0,
											   moveNPCBack:Boolean = false, childName:String = null,mode:String = "play", endLabel:* = Animation.LABEL_ENDING ) 
		{
			entity = char;
			
			this.partType = partType;
			this.startFrame = startFrame;
			this.mode = mode;
			this.endLabel = endLabel;
			this.childName = childName;
			this.action = action;
			this.knockBack = knockBack;
			this.moveNPCBack = moveNPCBack;
			this.hSpeed = hSpeed;
			this.spin = spin;
			this.spinFriction = spinFriction
			this.delay = delay;
			
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			_callback = callback;
			_group = group;
			
			// check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				_dir = -1;
			}
			
			// get timeline
			var part:Entity = SkinUtils.getSkinPartEntity(entity, partType);
			var timeline:Timeline;
			var clip:MovieClip = MovieClip(part.get(Display).displayObject);
			_hitBox = clip["hitBox"];
			if (childName)
			{
				clip = MovieClip(part.get(Display).displayObject);
				part = TimelineUtils.convertClip(clip[childName], group);
				timeline = part.get(Timeline);
				var tempclip:MovieClip = clip[childName];
				_hitBox = tempclip["hitBox"];
			}
			else
			{
				timeline = part.get(Timeline);
			}
			
			switch(mode)
			{
				case "gotoAndPlay":
					timeline.gotoAndPlay(startFrame);
					break;
				case "gotoAndStop":
					timeline.gotoAndStop(startFrame);
					break;
				case "stop":
					timeline.stop();
					break;
				case "play":
					timeline.play();
					break;
			}
			_hitBox.addEventListener(Event.ENTER_FRAME,CheckNPCCollision);
			TimelineUtils.onLabel( part, endLabel, doneAnim );
		}
		
		private function CheckNPCCollision(e:Event):void
		{
			//check if you have hit npc yet
			if(!_hitNPC)
			{
				var container:DisplayObjectContainer = super.entity.get(Display).container.parent;
				// check each NPC
				var npcList:NodeList = _group.systemManager.getNodeList( NpcNode );
				var npcNode:NpcNode;
				for( npcNode = npcList.head; npcNode; npcNode = npcNode.next )
				{
					// get NPC entity and display object
					var npcEntity:Entity = npcNode.entity;
					var npcClip:DisplayObjectContainer = npcEntity.get(Display).displayObject;
					
					// exclude pop follower and ad bitmap npcs
					var npcID:Id = npcEntity.get(Id);
					if ((npcID) && (npcID.id.indexOf("popFollower") == 0) || (npcID) && (npcID.id.substr(0,7) == "limited"))
						continue;
					
					// skip mannequins
					if ((npcEntity.has(Character)) && (npcEntity.get(Character).variant == CharacterCreator.VARIANT_MANNEQUIN))
						continue;
					
					// get bounding box in common parent's coordinate space
					var itemRect:Rectangle = _hitBox.getBounds(container);
					var npcRect:Rectangle = npcClip.getBounds(container);
					
					// shrink rect for NPC so collision happens further in	
					npcRect.inflate(-20,0);
					
					// find the intersection of the two bounding boxes
					var intersectionRect:Rectangle = npcRect.intersection(itemRect);
					
					// if colliding with NPC
					if ((intersectionRect != null) && (intersectionRect.size.length > 0))
					{
						trace("SkinFrameHitBoxAction :: CheckNPCCollision :: HIT NPC!");
						switch(action)
						{
							case "knock":
								// knock back npc
								if (!npcEntity.has(Motion))
									npcEntity.add(new Motion());
								var npcMotion:Motion = npcEntity.get(Motion);
								npcMotion.velocity.x = (knockBack * _dir) / 3;
								npcMotion.friction = new Point(1000, 0);
								CharUtils.setAnim( npcEntity, Hurt, false, 0, 0, true, true);
								// wait for end, then trigger returnToStand
								npcEntity.get(Timeline).handleLabel( "ending", Command.create(returnToStand, npcEntity), false );
								_hitNPC = true;
								break;
							case "flip":
								if (!npcEntity.has(Motion))
									npcEntity.add(new Motion());
								var NPCMotion:Motion = npcEntity.get(Motion);
								NPCMotion.rotationVelocity = spin;
								NPCMotion.rotationFriction = spinFriction;
								NPCMotion.velocity.x = hSpeed;
								CharUtils.setAnim( npcEntity, Hurt, false, 0, 0, true, true);
								// turn off wandering
								if (npcEntity.has(CharacterWander))
									npcEntity.get(CharacterWander).disabled = true;
								SceneUtil.addTimedEvent(_group, new TimedEvent(delay, 0, Command.create(resetNPC,npcEntity)));
								_hitNPC = true;
								break;
							
						}
						
					}
				}
			}
		}
		/**
		 * When part timeline done 
		 */
		private function doneAnim():void
		{
			_hitBox.removeEventListener(Event.ENTER_FRAME,CheckNPCCollision);
			_callback();
		}
		private function resetNPC(npc:Entity):void
		{
			_hitBox.removeEventListener(Event.ENTER_FRAME,CheckNPCCollision);
			CharUtils.setAnim(npc, Stand);
			var npcMotion:Motion = npc.get(Motion);
			npcMotion.zeroMotion();
			//if we want to set npc to go to target:
			var char:Character = npc.get(Character);
			if(moveNPCBack == true)
				CharUtils.moveToTarget(npc,char.currentCharData.position.x,char.currentCharData.position.y);
			_hitNPC = false;
			
		}
		private function returnToStand(npc:Entity):void
		{
			// set stand animation
			CharUtils.setAnim(npc, Stand);
			var npcMotion:Motion = npc.get(Motion);
			npcMotion.zeroMotion();
			//if we want to set npc to go to target:
			var char:Character = npc.get(Character);
			if(moveNPCBack == true)
				CharUtils.moveToTarget(npc,char.currentCharData.position.x,char.currentCharData.position.y);
			_hitNPC = false;
		}
	}
}

