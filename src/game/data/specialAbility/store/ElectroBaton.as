package game.data.specialAbility.store
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Sword;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.shrink.livingRoomShrunk.Particles.StaticElectricity;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	
	public class ElectroBaton extends SpecialAbility
	{
		private var emitterEntity:Entity;
		override public function init(node:SpecialAbilityNode):void
		{
			super.init(node);
			var sparks:StaticElectricity = new StaticElectricity(new Rectangle(-50, -50, 100,100),25,5,25,1,25);
			var container:DisplayObjectContainer = EntityUtils.getDisplayObject(SkinUtils.getSkinPartEntity(node.entity, SkinUtils.ITEM));
			if(_emitterContainer)
			{
				container = container["active_obj"][_emitterContainer];
			}
			emitterEntity = EmitterCreator.create(parent, container, sparks,0,0,null,"batonSparks",null,false);
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{	
			if ( !super.data.isActive )
			{
				var currentState:String = CharUtils.getStateType(entity)
				if(currentState == CharacterState.STAND || currentState == CharacterState.CLIMB)
				{
					setActive( true );
					
					// lock controls
					CharUtils.lockControls( super.entity, true, false );
					
					// set animation and listeners
					CharUtils.setAnim( super.entity, _animationClass );
					CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_ENDING, completed );
					CharUtils.getTimeline( super.entity ).handleLabel(_triggerFrame, zap );
				}
			}
		}
		
		private function zap():void
		{
			var emitter:Emitter = emitterEntity.get(Emitter);
			emitter.resume = true;
			emitter.emitter.counter.resume();
		}
		
		private function completed():void
		{
			super.setActive( false );
			
			Emitter(emitterEntity.get(Emitter)).emitter.counter.stop();
			
			// restore avatar
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
		}
		
		public var _animationClass:Class = Sword;
		public var _triggerFrame:String = "fire";
		public var _emitterContainer:String;
	}
}