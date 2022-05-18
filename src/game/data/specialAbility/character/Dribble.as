package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.part.SyncBounce;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.data.animation.entity.character.RunNinja;
	import game.data.animation.entity.character.StandNinja;
	import game.data.animation.entity.character.Throw;
	import game.data.animation.entity.character.WalkNinja;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.systems.entity.character.part.SyncBounceSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.RunState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.entity.character.states.touch.StandState;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class Dribble extends SpecialAbility
	{
		public var _bounceTime:Number = 1;
		public var _bouncieness:Number = .9;
		
		public var velX:Number = 600;
		public var velY:Number = -600;
		public var acc:Number = 800;
		
		private const OFFSET:Number = 25;
		private var ball:Entity;
		private var item:Entity;
		private var dribble:SyncBounce;
		private var spatial:Spatial;
		private var handPosition:Spatial;
		private var userSpatial:Spatial;
		private var edge:Edge;
		private var follower:Entity;
		
		private var spriteContainer:Sprite;
		private var targetContainer:DisplayObjectContainer;
		
		private var standAnim:Class;
		private var walkAnim:Class;
		private var runAnim:Class;
		
		private var fsm:FSMControl;
		
		private var validStates:Array = [CharacterState.RUN, CharacterState.STAND, CharacterState.SKID, CharacterState.WALK];
		
		private var shooting:Boolean;
		
		private var owningGroup:DisplayGroup
		
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			owningGroup = node.entity.group as DisplayGroup;
			
			fsm = node.entity.get(FSMControl);
			if(fsm == null)
				return;
			
			fsm.stateChange = new Signal(String, Entity);
			fsm.stateChange.add(stateChanged);
			
			if(fsm.getState(CharacterState.STAND) != null)
			{
				standAnim = (fsm.getState( CharacterState.STAND ) as StandState ).standAnim;
				(fsm.getState( CharacterState.STAND ) as StandState ).standAnim = StandNinja;
				walkAnim = (fsm.getState( CharacterState.WALK ) as WalkState ).walkAnim;
				(fsm.getState( CharacterState.WALK ) as WalkState ).walkAnim = WalkNinja;
				runAnim = (fsm.getState( CharacterState.RUN ) as RunState ).runAnim;
				(fsm.getState( CharacterState.RUN ) as RunState ).runAnim = RunNinja;
			}
			
			edge = node.entity.get(Edge);
			userSpatial = node.entity.get(Spatial);
			
			item = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.ITEM);
			
			spriteContainer = new Sprite();
			targetContainer = EntityUtils.getDisplayObject(node.entity);
			follower = EntityUtils.createSpatialEntity(owningGroup, spriteContainer, targetContainer.parent);
			follower.add(new FollowTarget(userSpatial));
			
			var sprite:Sprite = owningGroup.createBitmapSprite(EntityUtils.getDisplayObject(item),1,null,true,0,null,false);
			ball = EntityUtils.createSpatialEntity(owningGroup, sprite, spriteContainer);
			spatial = ball.get(Spatial);
			spatial.scale = userSpatial.scale;
			handPosition = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.HAND1).get(Spatial);
			
			if(owningGroup.getSystem(SyncBounceSystem) == null)
			{
				owningGroup.addSystem(new SyncBounceSystem());
			}
			
			dribble = new SyncBounce();
			dribble.bounceTime = _bounceTime;
			dribble.radius = OFFSET;
			ball.add(dribble);
			EntityUtils.visible(item, false);
			super.setActive(true);
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if(!shooting)
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					doToss();
				}
			}
		}
		
		private function doToss():void
		{
			CharUtils.lockControls( super.entity, true, false );
			CharUtils.setAnim( super.entity, Throw );
			
			shooting = true;
			
			if(owningGroup.getSystem(ThresholdSystem) == null)
				owningGroup.addSystem(new ThresholdSystem());
			
			ball.remove(SyncBounce);
			spatial.x = handPosition.x * userSpatial.scaleX;
			spatial.y = handPosition.y * userSpatial.scaleY;
			
			var motion:Motion = new Motion();
			motion.velocity = new Point( velX * -userSpatial.scaleX, velY);
			motion.acceleration = new Point(0, acc);
			ball.add(motion);
			
			var threshold:Threshold = new Threshold("y", ">", null, OFFSET);
			threshold.threshold = 0;
			threshold.entered.addOnce(bounce);
			ball.add(threshold);
		}
		
		private function bounce():void
		{
			var motion:Motion = ball.get(Motion);
			var threshold:Threshold = ball.get(Threshold);
			threshold.property = "x";
			threshold.offset = 0;
			if(motion.x > 0)
			{
				motion.velocity.x = -Math.abs(motion.velocity.x);
				threshold.operator = "<";
			}
			else
			{
				motion.velocity.x = Math.abs(motion.velocity.x);
				threshold.operator = ">";
			}
			motion.velocity.y *= -1;
			threshold.entered.addOnce(bouncedBack);
		}
		
		private function bouncedBack():void
		{
			ball.remove(Motion);
			ball.remove(Threshold);
			ball.add(dribble);
			
			shooting = false;
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
		}
		
		private function stateChanged(state:String, entity:Entity):void
		{
			var valid:Boolean = validStates.indexOf(state) != -1;
			toggleDribble(valid);
		}
		
		private function toggleDribble(valid:Boolean):void
		{
			EntityUtils.visible(item, !valid);
			EntityUtils.visible(ball, valid);
			DisplayUtils.moveToOverUnder(spriteContainer, targetContainer, true);
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(shooting)
				return;
			
			spatial.x = (handPosition.x - OFFSET) * userSpatial.scaleX;
			var top:Number = handPosition.y * userSpatial.scale;
			var bottom:Number = edge.rectangle.bottom;
			var delta:Number = bottom - top;
			
			dribble.startY = top + delta/2;
			dribble.radius = delta/2;
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			if(fsm == null)
				return;
			fsm.stateChange.remove(stateChanged);
			if(standAnim)
			{
				(fsm.getState( CharacterState.STAND ) as StandState ).standAnim = standAnim;
				(fsm.getState( CharacterState.WALK ) as WalkState ).walkAnim = walkAnim;
				(fsm.getState( CharacterState.RUN ) as RunState ).runAnim = runAnim;
			}
			
			setActive(false);
			EntityUtils.visible(item);
			node.entity.group.removeEntity(follower);
			ball = null;
		}
	}
}