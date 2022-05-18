// Used by:
// Card 2859

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.VortexSwirlParticles;
	import game.util.CharUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	/**
	 * Particle animation with vortex swirl
	 * 
	 * Required params:
	 * swfPath				String		Path to swf file
	 * 
	 * Optional params:
	 * offsetY				Integer		Offset from char
	 * epsilon				Integer		Gravity well epsilon
	 */
	public class VortexSwirl extends SpecialAbility
	{				
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			// load asset
			if (!_loaded)
			{
				super.loadAsset(_swfPath, loadComplete);
			}
		}

		/**
		 * When asset loaded 
		 */
		private function loadComplete(clip:Object = null):void
		{
			_loaded = true;
			_swf = MovieClip(clip);
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if asset is loaded then do particles on trigger
			if (_loaded)
			{
				CharUtils.getTimeline( node.entity ).handleLabel("trigger", addParticles);
			}
		}
		
		public function addParticles():void
		{
			var charSpatial:Spatial = super.entity.get(Spatial);
			
			// Add the particles
			_emitter = new VortexSwirlParticles();
			_emitter.init(_swf, charSpatial, _offsetY, _epsilon);
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, 0, 40, null, "VortexSwirl", charSpatial, true, true );					
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{	
			if(_emitterEntity)
			{
				super.group.removeEntity(_emitterEntity);
				_emitter = null;
				_emitterEntity = null;
			}
		}
		
		public var _swfPath:String;
		public var _offsetY:Number = -80;
		public var _epsilon:Number = 50;

		private var _swf:MovieClip;
		private var _loaded:Boolean = false;
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}