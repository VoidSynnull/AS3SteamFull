// Used by:
// Card "bow" on Con3 island using item bow

package game.data.specialAbility.islands.poptropicon
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.motion.easing.Quadratic;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Hazard;
	import game.components.hit.ValidHit;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.DrawBow;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scenes.arab2.treasureKeep.particles.GoldSparkle;
	import game.scenes.con3.Con3Events;
	import game.scenes.con3.shared.WrappedSignal;
	import game.systems.entity.character.states.CharacterState;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	/**
	 * Shoot arrow from bow
	 * 
	 * Required params:
	 * arrowPath	String		Path to arrow such as scenes/con3/arrow.swf
	 * 
	 * Optional params:
	 * targetId		String		
	 * speed		Number		Arrow speed (default is 900)
	 * offsetX		Number		X offset (default is 1)
	 * offsetY		Number		Y offset (default is 1)
	 * lifetime		Number		Arrow lifetime (default is 3.0)
	 */
	public class ShootBow extends SpecialAbility
	{
		override public function init( node:SpecialAbilityNode ):void
		{
			// need this if we want to load assets
			super.init(node);
			
			var bowButton:Entity = super.group.getEntityById( "bowButton" );
			var button:Button;
			if( bowButton )
			{
				button = bowButton.get( Button );
				button.isSelected = true;
			}
			bowTimeline = SkinUtils.getSkinPartEntity(node.entity, SkinUtils.ITEM);
			
			// enable super arrows for boss fight
			setPoweredBow();
			
			super.loadAsset(_arrowPath, loadComplete);
			
			if(charged)
				super.loadAsset("scenes/arab2/shared/glint_particle.swf", setupArrowSpark);
		}
		
		private function setPoweredBow():void
		{
			var clip:MovieClip = Display(bowTimeline.get(Display)).displayObject;
			
			// check event
			charged = super.shellApi.checkEvent(_events.WEAPONS_POWERED_UP);
			if(charged){
				// glow
				//clip.removeChild( clip["normal"]);
				clip["normal"].visible = false;
				clip["normal"].alpha = 0;
			}
			else{
				clip["powered"].visible = false;
				clip["powered"].alpha = 0;
			}
		}
		
		private function setupArrowSpark(Clip:MovieClip):void
		{
			if(Clip){
				_sparkClip = Clip;
			}
		}
		
		private function loadComplete(clip:MovieClip):void
		{
			_arrowClip = clip;
			_loaded = true;
		}
		
		override public function activate(node:SpecialAbilityNode):void
		{
			if( (_arrowPath) && (CharUtils.getStateType(node.entity) == CharacterState.STAND) && (!data.isActive) )
			{
				if(_loaded){
					//_shooting = false;
					
					super.setActive(true);
					//lock, raise hands, place arrow in hand, draw back bow, fire arrow, begin hit testing
					SceneUtil.lockInput(super.group, true);
					
					var rigAnim:RigAnimation = CharUtils.getRigAnim( node.entity, 1 );
					if ( rigAnim == null )
					{
						var animationSlot:Entity = AnimationSlotCreator.create( node.entity );
						rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
					}
					rigAnim.next = DrawBow;
					// animation apply to the front hand and arm only
					rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.ARM_FRONT, CharUtils.HAND_BACK, CharUtils.ARM_BACK);
					// wait for drawn back hand
					CharUtils.getTimeline(node.entity, 1).handleLabel("raised", drawBow);
				}
			}
		}
		
		// animate bow drawing, position arrow into the scene
		private function drawBow():void
		{
			if (_loaded && bowTimeline.has(Timeline))
			{
				Timeline(bowTimeline.get(Timeline)).gotoAndPlay("draw");
				Timeline(bowTimeline.get(Timeline)).handleLabel("fire", shoot);
				
				if( !_arrow )
				{
					if( !_arrowSequence )
					{
						_arrowSequence = BitmapTimelineCreator.createSequence( _arrowClip, true, PerformanceUtils.defaultBitmapQuality );
					}
					_arrow = makeTimeline(_arrowClip, super.entity.get(Display).container, false, _arrowSequence );
					_arrow.add(new Sleep(false,true));
					if(charged){
						Timeline(_arrow.get(Timeline)).gotoAndStop("super");
					}else{
						Timeline(_arrow.get(Timeline)).gotoAndStop("norm");
					}
					currentHit = new CurrentHit();
					_arrow.add(currentHit);
					_arrow.add(new WallCollider());
					_arrow.add(new BitmapCollider());
					_arrow.add(new SceneCollider());
					_arrow.add( new ValidHit( "wall", "ceiling", "tab_blocker1", "tab_blocker2"
											, "tab_blocker3", "target0", "target1", "target2", "target3"
											, "target4", "target5", "target6", "target_core", "barrierW0"
											, "barrierW1", "barrierW2", "force_shield"
											, "laserhit_1_1", "laserhit_1_2", "laserhit_1_3"
											, "laserhit_2_1", "laserhit_2_2", "laserhit_3_1"
											, "laserhit_4_1", "laserhit_4_2", "laserhit_5_1"
											, "laserhit_5_2", "laserhit_6_1", "laserhit_6_2"
											, "barrier0_shield", "barrier1_shield", "barrier2_shield"
											, "barrier3_shield", "barrier4_shield" ));
				}
				else
				{
					Sleep( _arrow.get( Sleep )).sleeping = false;
					Display( _arrow.get( Display )).alpha = 1;
					CurrentHit( _arrow.get( CurrentHit )).hit = null;
				}
				// set starting location of arrow in scene			
				var hand:Entity = CharUtils.getJoint(super.entity, CharUtils.HAND_BACK);
				var handSpatial:Spatial = hand.get(Spatial);
				var avatar:DisplayObject = DisplayObject(super.entity.get(Display).displayObject);
				// point relative to avatar
				var point:Point = new Point((handSpatial.x - _offsetX / avatar.scaleY) - avatar.width+10, handSpatial.y + _offsetY / avatar.scaleY);
				point = avatar.localToGlobal(point);
				// point relative to scene
				point = avatar.parent.globalToLocal(point);
				// set avatar facing direction
				var dir:Number = 1;
				// Flip the object if you're facing Left
				if (super.entity.get(Spatial).scaleX > 0){
					dir = -1;
				}
				var spatial:Spatial = _arrow.get(Spatial);
				var motion:Motion = _arrow.get(Motion);
				spatial.x = point.x;
				spatial.y = point.y;
				// get rotation and angle of avatar
				// if flipped to right, then flip rotation
				if (dir == 1){
					_arrow.get(Spatial).rotation = 0;
					motion.velocity = new Point(-425, 0);
				}else{
					_arrow.get(Spatial).rotation = 180;
					motion.velocity = new Point(425, 0);
				}
				//SOUND
				AudioUtils.play(super.group,DRAW,1,false,null,null,1.1);
			}
			else
			{
				// if no arrow is loaded, then reset
				super.setActive(true);
				SceneUtil.lockInput(super.group, false);
				SceneUtil.setCameraTarget(super.group as Scene, super.entity);
			}
		}
		
		private function shoot():void
		{
			_shooting = true;
			
			// ADD HAZARD COLLISION DETECTION AFTER IT LEAVES BOW
			_arrow.add(new HazardCollider());
			//CharUtils.getTimeline(node.entity).stop();
			var dir:Number = 1;
			if (super.entity.get(Spatial).scaleX > 0){
				dir = -1;
			}
			var motion:Motion = _arrow.get(Motion);
			if (dir == 1){
				motion.velocity = new Point(_speed, 0);
			}else{
				motion.velocity = new Point(-_speed, 0);
			}
			_timer = 0;
			if(charged == true){
				// todo: add particles
				addArrowParticles();
				
				SceneUtil.lockInput(super.group, false);
			}else{
				//camera only follows target in non-charged form
				SceneUtil.setCameraTarget(super.group as Scene, _arrow);
			}
			//DisplayUtils.moveToBack(EntityUtils.getDisplayObject(_arrow));
			//SOUND
			AudioUtils.play(super.group, FIRE, 1, false, null, null, 1.1);
		}
		
		private function addArrowParticles():void
		{
			if(_arrow){
				var sparks:Emitter2D = new Emitter2D();
				sparks.counter = new Steady( 15 );
				var bitmapData:BitmapData = BitmapUtils.createBitmapData(_sparkClip);
				sparks.addInitializer(new ImageClass( GoldSparkle, [bitmapData], true ));
				sparks.addInitializer( new AlphaInit( .8, 1 ));
				sparks.addInitializer( new Position( new RectangleZone(-30,-5,5,5)));
				sparks.addInitializer( new Lifetime( 0.3, 0.6 ));
				sparks.addAction( new Age( Quadratic.easeIn ));
				sparks.addAction( new Move());
				sparks.addAction( new Accelerate( 0, 110 ));
				sparks.addAction( new RandomDrift( 0, 100 ));
				sparks.addAction( new Fade( 1, 0 ));
				sparkEmitter = EmitterCreator.create( super.group, super.entity.get(Display).container, sparks, 0, 0, _arrow, "star", _arrow.get(Spatial));
			}
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(_arrow && _shooting){
				if(_timer < _lifetime){
					_timer += time;
					hitTest(time);
				}else{
					_timer = 0;
					clearArrow(_arrow);
				}
			}
		}
		
		private function hitTest(time:Number):void
		{
			var hit:Boolean = false;
			// test for hits
			if(currentHit.hit){
				var id:String = Id(currentHit.hit.get(Id)).id;			
				if(id.substr(0,_targetId.length) == _targetId){
					// destroy hit target
					destroyTarget(currentHit.hit);
				}
				else{
					// NEED LASERS TO BLOCK ARROWS
					if( currentHit.hit.has( Hazard ))
					{
						clearArrow( _arrow );
						// MAYBE ADD SOME EFFECTS HERE
					}
					else
					{
						reset();
					}
				}
				//hit SOUND
				
				if( id == "target_core" )
				{
					AudioUtils.play(super.group, CRYSTAL_HIT, 1, false, null, null, 1.1);
				}
				else
				{
					AudioUtils.play(super.group, HIT, 1, false, null, null, 1.1);
				}
			}
		}
		
		private function destroyTarget(target:Entity):void
		{
			// send out signal to target
			var sig:WrappedSignal = target.get(WrappedSignal);
			if(sig && sig.signal.numListeners > 0){
				sig.signal.dispatch(target);
				//_shooting = false;
				//_group.removeEntity(_arrow);
				reset(false);
			}
			else{
				reset();
			}
		}
		
		private function reset(returnCamera:Boolean = true):void
		{
			_shooting = false;
			
			if( currentHit.hit.has( Motion ))
			{
				var motion:Motion = currentHit.hit.get( Motion );
				var arrowMotion:Motion = _arrow.get( Motion );
				arrowMotion.velocity.x = motion.velocity.x;
				arrowMotion.velocity.y = motion.velocity.y;
			}
			
			// fade
			if(charged){
				TweenUtils.entityTo(_arrow, Display, 0.6, {alpha:0, onComplete:Command.create(clearArrow, _arrow, false)},"",0.2);
			}
			else{
				TweenUtils.entityTo(_arrow, Display, 2, {alpha:0, onComplete:Command.create(clearArrow, _arrow, returnCamera)},"",0.4);
			}
			//_group.removeEntity(_arrow);
			//super.setActive(false);
			if(sparkEmitter && sparkEmitter.has(Emitter)){
				Emitter(sparkEmitter.get(Emitter)).emitter.counter.stop();  
			}
		}
		
		private function clearArrow(arrow:Entity, returnCamera:Boolean = true):void
		{
			if(returnCamera){
				if(currentHit.hit){
					var id:Id = currentHit.hit.get( Id );
					if( id.id != "target_core" )
					{
						SceneUtil.lockInput(super.group, false);
						SceneUtil.setCameraTarget(super.group as Scene, super.entity);
					}
				}else{
					SceneUtil.lockInput(super.group, false);
					SceneUtil.setCameraTarget(super.group as Scene, super.entity);
				}
			}
			Sleep( arrow.get( Sleep )).sleeping = true;
			_shooting = false;
			MotionUtils.zeroMotion(arrow);
	//		_group.removeEntity(arrow);
			super.setActive(false);
		}
		
		override public function deactivate(node:SpecialAbilityNode):void
		{
			if(_arrow){
				//reset(node); 
				super.group.removeEntity(_arrow);
			}
			if( _arrowSequence )
			{
				_arrowSequence.destroy();
				_arrowSequence = null;
			}
			
			var bowButton:Entity = super.group.getEntityById( "bowButton" );
			var button:Button;
			if( bowButton )
			{
				button = bowButton.get( Button );
				button.isSelected = false;
			}
		}
		
		private function makeTimeline(clip:MovieClip, container:DisplayObjectContainer, play:Boolean = true, seq:BitmapSequence = null):Entity
		{
			var target:Entity = EntityUtils.createMovingTimelineEntity(super.group, clip, container, play);
			target = BitmapTimelineCreator.convertToBitmapTimeline(target, clip, true, seq, PerformanceUtils.defaultBitmapQuality);
			return target; 
		}
		
		public var required:Array = ["arrowPath"];
		
		public var _arrowPath:String;
		public var _targetId:String = "target";
		public var _speed:Number = 900;
		public var _offsetX:Number = 1;;
		public var _offsetY:Number = 1;
		public var _lifetime:Number = 3.0;
		
		public var charged:Boolean = false;
		
		private var _arrowClip:MovieClip;
		private var _arrow:Entity;
		private var _arrowSequence:BitmapSequence;
		private var _loaded:Boolean;
		private var _shooting:Boolean; 
		private var _timer:Number;
		private var currentHit:CurrentHit;
		private var _events:Con3Events;
		private var _sparkClip:MovieClip;
		private var sparkEmitter:Entity;
		private var bowTimeline:Entity;
		
		private const WHOOSH:String = SoundManager.EFFECTS_PATH + "arrow_whoosh_01.mp3";
		private const DRAW:String = SoundManager.EFFECTS_PATH + "wood_creak_03.mp3";
		private const FIRE:String = SoundManager.EFFECTS_PATH + "arrow_whoosh_01.mp3";
		private const HIT:String = SoundManager.EFFECTS_PATH + "arrow_01.mp3";
		private const CRYSTAL_HIT:String = SoundManager.EFFECTS_PATH + "electric_glass_break_01.mp3";		
	}
}