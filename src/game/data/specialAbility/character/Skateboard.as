// Used by:
// Card 2759 using avatar item limited_caprisun_skate

package game.data.specialAbility.character 
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.group.Scene;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Jump;
	import game.data.animation.entity.character.Stand;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CameraGroup;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.initializers.ChooseInitializer;
	import org.flintparticles.common.initializers.ExternalImage;
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	/**
	 * Ride skateboard back and forth with effects (since skateboard is added to avatar, it will be automatically scaled down by 36%)
	 * 
	 * Required params:
	 * swfPath				String		Path to swf file for skateboard
	 * 
	 * Optional params:
	 * speedY				Number		Vertical jump speed (default is -15)
	 * accelY				Number		Vertical acceleration/gravity (default is -0.5)
	 * offsetY				Number		Vertical offset from ground to top of skateboard (default is 25)
	 * maxSpeedH			Number		Maximum horizontal speed going left and right (default is 25)
	 * accelH				Number		Horizontal acceleration until reach max speed (default is 0.1)
	 * maxRuns				Number		Number of back and forth runs (default is 2)
	 * 
	 * NOTE: Particles don't work on the web for this ability!!!!
	 * particlesOffsetX		Number		Offset from center of player to start particles (default is 70)
	 * particlesOffsetY		Number		Offset from center of player to start particles (default is 22)
	 * particlesRadius		Number		Radius from start position for particles (default is 4)
	 * particlesPath		String		Path to swf file for particle
	 * particlesClass		Class		Particles class
	 */
	public class Skateboard extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if not active and standing
			if (( !super.data.isActive ) && (CharUtils.getStateType(entity) == CharacterState.STAND))
			{
				// init vars
				jumping = false;
				skating = false;
				count = 0;
				runs = 0;
				
				// make active
				super.setActive( true );
				
				// lock inputs
				CharUtils.lockControls( entity, true, true);
				SceneUtil.lockInput(group, true);
				
				// load skateboard
				super.loadAsset(_swfPath, loadComplete);
			}
		}
		
		/**
		 * when skateboard completes loading 
		 * @param clip
		 */
		protected function loadComplete(clip:MovieClip):void
		{
			// return if no clip
			if (clip == null)
				return;
			
			// add skateboard to avatar
			entity.get(Display).displayObject.addChild(clip);
			skateboard = clip;
			
			// convert to timeline if more than one frame
			if (clip.totalFrames > 1)
				skateboardEntity = TimelineUtils.convertClip(clip, group);
			else
				skateboardEntity = EntityUtils.createDisplayEntity(group, clip);
			
			// scale up to match avatar scale
			clip.scaleX = clip.scaleY = 1/0.36;
			
			// position skateboard so bottom of skateboard aligns to player's feet
			clip.y = SKATEBOARD_OFFSET;
			
			// hide skateboard in hand
			var itemPart:Entity = CharUtils.getPart(entity, CharUtils.ITEM);
			itemPart.get(Display).visible = false;
			
			// get direction
			var playerSpatial:Spatial = super.entity.get(Spatial);
			direction = playerSpatial.scaleX > 0 ? -1 : 1;
			
			// get starts
			startX = playerSpatial.x;
			startY = playerSpatial.y;
			
			// start jump
			jumping = true;
			CharUtils.setAnim(entity, Jump);
			
			// save and remove motion component
			savedMotion = entity.get( Motion );
			entity.remove( Motion);
			
			// save and remove motion bounds
			savedBounds = entity.get ( MotionBounds );
			entity.remove( MotionBounds );
			
			// load particles assets if any
			if (_particlesPath)
				super.loadAsset(_particlesPath, loadParticlesComplete);
		}
		
		/**
		 * when skateboard completes loading 
		 * @param clip
		 */
		protected function loadParticlesComplete(clip:MovieClip):void
		{
			particleClip = clip;
		}

		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			var spatial:Spatial = entity.get( Spatial );
			
			// if in jumping mode
			if (jumping)
			{
				count++;
				// vertical offset
				var offset:Number = count*_speedY + count*count*_accelY;
				// update char and skateboard
				spatial.y = startY + offset;
				skateboard.y = SKATEBOARD_OFFSET + 1/0.36 * (startY - spatial.y);
				
				// if hit skateboard
				if ((count > 2) && (spatial.y >= startY - _offsetY))
				{
					// set to skating mode
					jumping = false;
					skating = true;
					count = 0;
					
					// force final positions
					spatial.y = startY - _offsetY;
					skateboard.y = SKATEBOARD_OFFSET + 1/0.36*_offsetY;
					
					// don't follow char with camera
					var cameraGroup:CameraGroup = group.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
					if ( cameraGroup )
						cameraGroup.target = new Spatial(startX, startY);
					
					// play frame two if timeline
					if (skateboardEntity.get(Timeline))
						skateboardEntity.get(Timeline).gotoAndPlay(1);
					
					// make char stand
					CharUtils.setAnim(entity, Stand);
					
					// init particles
					if ((_particlesClass) && (particleClip))
					{
						emitter = new _particlesClass();
						// use ExternalImage because we need multiple particles (using ShareImage doesn't work)
						emitter.addInitializer( new ChooseInitializer([new ExternalImage(super.shellApi.assetPrefix + _particlesPath, true)]));
						emitter.init(entity.get(Spatial), _particlesOffsetX, _particlesOffsetY, _particlesRadius);
						emitterEntity = EmitterCreator.create( group, entity.get(Display).container, emitter as Emitter2D, 0, 0, entity, "skateboard_sparks", entity.get(Spatial));
					}
				}
			}
			// if in skating mode
			else if (skating)
			{
				count++;
				
				// force avatar and skateboard y positions
				skateboard.y = SKATEBOARD_OFFSET + 1/0.36*_offsetY;
				spatial.y = startY - _offsetY;
				
				// calc speed with acceleration
				var newSpeed:Number = count*count*_accelH;
				// limit to max
				if (newSpeed > _maxSpeedH)
					newSpeed = _maxSpeedH;
				spatial.x += (newSpeed * direction);
				
				// if go offscreen, then flip
				if (Math.abs(spatial._x - startX) > shellApi.viewportWidth)
				{
					runs += 0.5;
					direction *= -1;
					spatial.scaleX *= -1;
				}
				// if max run and near starting point, then end
				if ((runs == _maxRuns) && (Math.abs(spatial._x - startX) < _maxSpeedH))
				{
					// restore position
					spatial._y = startY;
					spatial._x = startX;
					// end animation
					endAnim();
				}
			}
			super.update(node, time);
		}

		private function endAnim():void
		{
			// show skateboard in hand
			CharUtils.getPart(entity, CharUtils.ITEM).get(Display).visible = true;
			// free char
			CharUtils.lockControls( entity, false, false );
			CharUtils.stateDrivenOn( entity );
			// unlock input
			SceneUtil.lockInput(group, false);
			// remove skateboard
			entity.get(Display).displayObject.removeChild(skateboard);
			// set camera pan to char
			SceneUtil.setCameraTarget(Scene(group), entity);
			// restore motion
			entity.add( savedMotion );
			entity.add( savedBounds );
			// set inactive
			super.setActive( false );
			// stop emitter
			if (emitter)
			{
				emitter.counter.stop();
				// remove emitter
				group.removeEntity(emitterEntity);
			}
		}
		
		private const SKATEBOARD_OFFSET:Number = 108;
		
		public var _swfPath:String;
		public var _speedY:Number = -15;
		public var _accelY:Number = 0.5;
		public var _offsetY:Number = 25;
		public var _maxSpeedH:Number = 25;
		public var _accelH:Number = 0.1;
		public var _maxRuns:Number = 2;
		public var _particlesOffsetX:Number = 70;
		public var _particlesOffsetY:Number = 22;
		public var _particlesRadius:Number = 4;
		public var _particlesPath:String;
		public var _particlesClass:Class;
		
		private var skateboardEntity:Entity;
		private var startY:Number;
		private var startX:Number;
		private var count:Number;
		private var jumping:Boolean = false;
		private var skating:Boolean = false;
		private var skateboard:MovieClip;
		private var direction:Number;
		private var runs:Number;
		private var savedMotion:Motion;
		private var savedBounds:MotionBounds;
		private var emitter:Object;
		private var emitterEntity:Entity;
		private var particleClip:MovieClip;
	}
}