// Used by:
// Cards 3041, 3147, 3221, 3230, 3296, 3327, 3328, 3337, 3369, 3466
// Used by ButtKite.as (archived)

package game.data.specialAbility.character
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.Draft;
	import game.components.motion.FollowTarget;
	import game.components.specialAbility.character.Balloon;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.particles.emitter.specialAbility.ConfettiBlast;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.DraftSystem;
	import game.systems.specialAbility.character.BalloonSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;

	/**
	 * Avatar holds balloon by string
	 * 
	 * Required params:
	 * swfPath				String			Path to balloon swf
	 * 
	 * Optional params:
	 * stringColor			Uint			Color of string (default is white)
	 * stringThickness		Number			Thickness of string (default is 1)
	 * directional			Boolean			Directional property of balloon (default is false)
	 * offsetX				Number			X offset from player (default is 5)
	 * offsetY				Number			Y offset from player (default is -200)
	 * knotX				Number			X knot location (default is 0)
	 * knowY				Number			Y knot location (default is 0)
	 * rate					Number			Balloon rate (default is 0.05)
	 * gravityDampening		Number			Gravity dampening (default is 0-off)
	 * clickable			Boolean			Balloon is clickable (default is false)
	 */
	public class AddBalloon extends SpecialAbility
	{
		private var _balloonSystem:BalloonSystem;
		
		
		override public function init( node:SpecialAbilityNode ):void
		{
			super.init(node);
			
		}
		
		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			
			specialClassLoaded = new Signal(SpecialAbilityData);

			if(_addedBalloon)
			{
				this.actionCall("setballoon_actions");
				
			}
			// only load one balloon
			if (!this.data.isActive)
			{
				charMotion = super.entity.get(CharacterMotionControl);
				
				super.loadAsset(_swfPath, loadComplete);
				this.data.isActive = true;
				_addedBalloon = true;
				if(_triggerable == true)
					this.data.triggerable = true;
			}
		}

		/**
		 * When balloon loaded 
		 * @param clip
		 */
		private function loadComplete(clip:MovieClip):void
		{
			if(!clip)
			{
				endBalloon();
				return;
			}
			
			if((charMotion == null) && !isNaN(_gravity))
			{
				endBalloon();
				return;
			}
			
			// Create balloon component and fill it in
			var balloon:Balloon = new Balloon(super.entity);
			balloon.directional = _directional;

			// set values
			balloon.restingPosition.x = _offsetX;
			balloon.restingPosition.y = _offsetY;
			balloon.knotPosition.x = _knotX;
			balloon.knotPosition.y = _knotY;
			balloon.stringColor = _stringColor;
			balloon.stringThickness = _stringThickness;
			
			// RLH: not all balloons have a shape clip
			if (clip.shape)
				clip.shape.gotoAndStop(0);
			
			if(_randomFrame)
				clip.gotoAndStop(randomMinMax(0,clip.totalFrames));
			//initial position
			var charspatial:Spatial = super.entity.get(Spatial);
			clip.x = charspatial.x + balloon.restingPosition.x;
			clip.y = charspatial.y + balloon.restingPosition.y;

			objectEntity = EntityUtils.createSpatialEntity(super.group, clip, super.entity.get(Display).container);
			data.entity = objectEntity;

			if(_clickable)
			{
				// we are in the card so different behavior
				if(clip.multiple)
				{
					
				}
				else
				{
					InteractionCreator.addToEntity(objectEntity, [InteractionCreator.CLICK]);
					objectEntity.get(Interaction).click.addOnce(popBalloon);
				}
				ToolTipCreator.addToEntity(objectEntity);
			}

			objectEntity.add(balloon).add(new FollowTarget(charspatial, _rate))
				.add(new Id("balloon"));

			if (clip.anim)
			{
				var timeline:Timeline = TimelineUtils.convertClip(clip.anim, super.group).get(Timeline);
				objectEntity.add(timeline);
				var tailClip:MovieClip = clip.anim.art.tail;
				if(tailClip != null)
				{
					var tail:Entity = EntityUtils.createMovingTimelineEntity(super.group, tailClip, tailClip.parent, true);
					tail.add(new Draft(super.entity.get(Motion), 2));
					if( !super.group.getSystem( DraftSystem ) )
					{
						super.group.addSystem( new DraftSystem(),SystemPriorities.updateAnim );
					}
				}
			}
			
			specialClassLoaded.dispatch(data);
			
		}

		/**
		 * When balloon clicked 
		 * @param entity
		 */
		private function popBalloon(entity:Entity):void
		{
			//confetti
			var pop:ConfettiBlast = new ConfettiBlast();
			pop.init(null, 10, 50);
			var ownerDisplay:DisplayObjectContainer = super.entity.get(Display).container;
			var balloonSpatial:Spatial = entity.get(Spatial);
			EmitterCreator.create(super.group, ownerDisplay, pop, balloonSpatial.x, balloonSpatial.y - balloonSpatial.height/2);
			//sound
			AudioUtils.play(super.group, SoundManager.EFFECTS_PATH + POP + GeomUtils.randomInt(1,POP_EFFECTS)+".mp3");

			super.shellApi.specialAbilityManager.removeSpecialAbility(super.entity, this.data.id);
		}

		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			
			if(_balloonSystem == null)
				_balloonSystem = super.group.addSystem( new BalloonSystem(),SystemPriorities.updateAnim ) as BalloonSystem;
			// if balloon is altering characters gravity
			if( (this.data.isActive) && (charMotion != null) && !isNaN(_gravity) )
			{
				var charState:String = CharUtils.getStateType(super.entity);
				var motion:Motion = super.entity.get(Motion);

				charMotion.jumpDampener = 1.25;
				if(charState == CharacterState.JUMP || charState == CharacterState.FALL)
				{
					if(motion.velocity.y > 0)
						charMotion.gravity = _gravity;
					else
						charMotion.gravity = MotionUtils.GRAVITY;
				}
			}
		}

		/**
		 * End balloon ability 
		 */
		private function endBalloon():void
		{
			// if characters gravity was altered, reset it
			if((charMotion != null) && !isNaN(_gravity))
			{
				charMotion.gravity = MotionUtils.GRAVITY;
				charMotion.jumpDampener = 1;
			}
			super.group.removeEntity(objectEntity);
			
			this.data.isActive = false;
		}

		override public function deactivate( node:SpecialAbilityNode ):void
		{
			endBalloon();
		}
		private function randomMinMax( minNum:Number, maxNum:Number ):Number
		{
			return (Math.floor(Math.random() * (maxNum - minNum + 1)) + minNum);
		}
		
		public var required:Array = ["swfPath"];
		
		public var _swfPath:String;
		public var _stringColor:uint = 0xFFFFFF;
		public var _stringThickness:Number = 1;
		public var _directional:Boolean = false;
		public var _offsetX:Number = 5;
		public var _offsetY:Number = -200;
		public var _knotX:Number = 0;
		public var _knotY:Number = 0;
		public var _rate:Number = .05;
		public var _gravity:Number;
		public var _clickable:Boolean = false;
		public var _linkedPrefix:String = "balloon_";
		public var _triggerable:Boolean;
		private var _currentMultiple:uint;
		private var _addedBalloon:Boolean=false;
		public var _randomFrame:Boolean=false;
		
		private const POP:String = "balloon_pop_0";
		private const POP_EFFECTS:uint = 3;
		private var charMotion:CharacterMotionControl;
		private var objectEntity:Entity;
	}
}