// Used by:
// Card 2475 using ability limited/rain_8ball (AssetRain class particles - falling 8 balls)
// Card 2628 using item limited_spongebob3d_icecream (AssetRain class particles - falling ice cream cones)
// Card 2662 using item limited_lalaloopsy_hair_bubble (AssetRain class particles - 3 kinds of falling taffy and hair animation)
// Card 3236 using ability binary_rain (Binary class particles - falling zeros and ones with blue tint and lasts forever until turned off)

package game.data.specialAbility.character
{	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Scene;
	
	import game.components.Emitter;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalSwfImage;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	import flash.display.MovieClip;
	
	/**
	 * Rain swfs in scene using particleRain emitter (can take multiple assets)
	 * 
	 * Required params: (either swfPath or swfPaths)
	 * swfPath			String		Path to swf that comprise rain
	 * swfPaths			Array		Array of swfs that comprise rain
	 * particleClass	Class		Particle class  (make sure to add class to dynamic manifest)
	 * 
	 * Optional params:
	 * speed			Number		Speed of falling (default is 400)
	 * scaleMin			Number		Minimum scale of object (default is 1)
	 * scaleMax			Number		Maximum scale of object (default is 1)
	 * doRotation		Boolean		Rotate object as it falls (default is false)
	 * duration			Number		Number of seconds that effect lasts (default is 0 = forever);
	 */
	public class RainAssets extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if not active
			if ( !super.data.isActive )
			{
				// convert single path to array
				if (_swfPath)
					_swfPaths = [_swfPath];
				
				// make active
				super.setActive( true );
				_reinitEmitters = false;
				
				// init arrays
				_assetClips = new Array();
				_emitters = new Array();
				
				// if duration
				if (_duration != 0)
				{
					// stop character and input
					MotionUtils.zeroMotion( super.entity );
					CharUtils.stateDrivenOff( super.entity );
					SceneUtil.lockInput( super.group );
				}
				
				// load assets
				super.loadAssets(_swfPaths, loadComplete);
			}
		}
		
		/**
		 * When assets loaded 
		 */
		private function loadComplete():void
		{
			var box:Rectangle = new Rectangle( 0, -400, super.shellApi.viewportWidth, super.shellApi.viewportHeight );
			var startVelocity : Point = new Point( 200, 0 );
			
			// for each asset
			for(var i:Number=0; i<_swfPaths.length; i++)
			{
				// init rain
				var rain:Object = new _particleClass();
				rain.init(box);
				// get clip from what has already been loaded
				var clip:MovieClip = super.shellApi.getFile(super.shellApi.assetPrefix + _swfPaths[i]);
				// pass clip to initializer (note that the clip can have multiple frames which will be chosen at random)
				rain.addInitializer( new ChooseInitializer([new ExternalSwfImage( clip )]) );
				rain.addInitializer( new Velocity( new PointZone( startVelocity ) ) );
				rain.addInitializer(new ScaleImageInit(_scaleMin, _scaleMax));
				rain.addAction(new Move());
				rain.addAction(new Accelerate( 0, _speed ));
				
				// all classes for this ability need to support this function
				rain.addPins(super.shellApi);
				
				// if rotatioin
				if(_doRotation)
				{
					rain.addInitializer(new RotateVelocity(-5, -10));
					rain.addAction(new Rotate());
				}
				
				// create emitter entity and add to array
				var emitterEntity:Entity = EmitterCreator.create( super.group, Scene(super.group).overlayContainer, rain as Emitter2D );
				_emitters.push(emitterEntity);
			}
			
			// trigger any now actions
			actionCall(SpecialAbilityData.NOW_ACTIONS_ID);
			
			// rain for 7 seconds
			if (_duration != 0)
				SceneUtil.addTimedEvent( super.group, new TimedEvent( _duration, 1, endRain));
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var display:DisplayObject;
			var emit:Emitter
			
			// if scene paused
			if(	super.shellApi.sceneManager.currentScene.paused)
			{
				// pause each emitter
				for(var i:int=0; i<_emitters.length; i++)
				{
					display = _emitters[i].get(Display).displayObject; 
					display.alpha = 0;
					emit = _emitters[i].get(Emitter);
					emit.pause = true;
				}
				_reinitEmitters = true;
			}
			else
			{
				// if scene not paused
				// if needing to reinitialize
				if(_reinitEmitters)
				{
					// turn on each emitter
					for(i=0; i<_emitters.length; i++)
					{
						display = _emitters[i].get(Display).displayObject; 
						display.alpha = 1;
						emit = _emitters[i].get(Emitter);
						emit.resume = true;
					}
					_reinitEmitters = false;
				}
			}
		}
		
		/**
		 * When rain ends 
		 */
		private function endRain():void
		{
			super.setActive( false );
			
			if (_duration != 0)
				SceneUtil.lockInput( super.group, false );
			
			// remove emitter entities
			removeEntities();
		}
		
		/**
		 * Remove emitter entities 
		 */
		private function removeEntities():void
		{
			// remove entities
			if (_emitters)
			{
				for(var i:Number=0;i<_emitters.length;i++)
				{
					super.group.removeEntity(_emitters[i]);
				}
			}
		}
		
		override public function removeSpecial(node:SpecialAbilityNode):void
		{
			// remove emitter entities
			removeEntities();
			super.removeSpecial(node);
		}

		public var required:Array = [["swfPath","swfPaths"], "particleClass"];
		public var _particleClass:Class;
		public var _swfPath:String;
		public var _swfPaths:Array;
		public var _speed:Number = 400;
		public var _scaleMin:Number = 1;
		public var _scaleMax:Number = 1;
		public var _doRotation:Boolean = false;
		public var _duration:Number = 0;
		
		private var _assetClips:Array;
		private var _emitters:Array;
		private var _reinitEmitters:Boolean = false;
	}
}
