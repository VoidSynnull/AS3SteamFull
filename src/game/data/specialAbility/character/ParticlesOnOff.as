// Used by:
// Card 3009 used by item pfairy1 (FairyWand particle class)

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	/**
	 * Apply particles to part that can be turned on/off
	 * 
	 * Required params:
	 * particleClass	Class		Particle class (make sure to add class to dynamic manifest)
	 * 
	 * Optional params:
	 * partType			String		Part type (default is "item");
	 */
	public class ParticlesOnOff extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			// toggle _emitter
			if(_particlesOn)
				removeEmitter();
			else
				addEmitter();
			_particlesOn = !_particlesOn;
		}
		
		/**
		 * Add emitter to part 
		 */
		private function addEmitter():void
		{
			// if emitter exists then remove
			if(_emitter)
			{
				_partEntity.group.removeEntity(_emitterEntity);
				_emitterEntity = null;
				_emitter = null;
			}
			
			// create new emitter
			_emitter = new _particleClass();
			_emitter.init();
			_partEntity = CharUtils.getPart(super.entity, _partType);
			
			// create emitter entity in part group
			var container:DisplayObjectContainer = _partEntity.get(Display).displayObject;
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, 0, 0 );
		}
		
		/**
		 * Stop emitter 
		 */
		private function removeEmitter():void
		{	
			_emitter.stopEmitter();
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			if (_emitterEntity)
				_partEntity.group.removeEntity(_emitterEntity);
		}
		
		public var required:Array = ["particleClass"];
		
		public var _particleClass:Class;
		public var _partType:String = "item";
		
		private var _particlesOn:Boolean = false;
		private var _partEntity:Entity;
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}