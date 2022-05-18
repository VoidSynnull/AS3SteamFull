// Used by:
// Card 2871

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.creators.entity.EmitterCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.GustBlowParticles;
	import game.util.CharUtils;
	
	import org.flintparticles.twoD.emitters.Emitter2D;

	/**
	 * Particle animation to simulate leaves blowing by in gust
	 * 
	 * Required params:
	 * swfPath				String		Path to swf file
	 * 
	 * Optional params:
	 * speedYMin			Integer		Minimum y speed
	 * speedYMax			Integer		Maximum y speed
	 * speedX				Integer		x speed
	 * spikeRad				Integer		Spike radius in x direction
	 * spikeInc				Float		Spike increment per frame
	 */
	public class GustBlow extends SpecialAbility
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
				// for salute
				CharUtils.getTimeline( node.entity ).handleLabel("stop", addParticles);
				// for strum
				CharUtils.getTimeline( node.entity ).handleLabel("trigger", addParticles);
			}
		}
		
		public function addParticles():void
		{
			var charSpatial:Spatial = super.entity.get(Spatial);
			var scene:MovieClip = super.entity.get(Display).displayObject.parent;
			var point:Point = new Point(charSpatial.x + scene.x + 480, charSpatial.y + scene.y + 320);
			
			// Add the particles
			_emitter = new GustBlowParticles();
			_emitter.init(_swf, _speedYMin, _speedYMax, _speedX, _spikeRad, _spikeInc);
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			
			// need to offset from viewport (or parent to scene?)
			_emitterEntity = EmitterCreator.create( group, container, _emitter as Emitter2D, -point.x, -point.y, null, "GustBlow", charSpatial);					
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
		public var _speedYMin:Number = 90;
		public var _speedYMax:Number = 180;
		public var _speedX:Number = 600;
		public var _spikeRad:Number = 15;
		public var _spikeInc:Number = 0.125;

		private var _swf:MovieClip;
		private var _loaded:Boolean = false;
		private var _emitter:Object;
		private var _emitterEntity:Entity;
	}
}