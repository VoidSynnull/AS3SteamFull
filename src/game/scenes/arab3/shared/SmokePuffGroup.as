package game.scenes.arab3.shared
{
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Parent;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Attack;
	import game.data.animation.entity.character.Genie;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Sword;
	import game.data.character.part.eye.EyeBallData;
	import game.data.sound.SoundModifier;
	import game.managers.EntityPool;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.systems.entity.EyeSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Back;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.GravityWell;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class SmokePuffGroup extends Group
	{
		public var smokeLoadCompleted:Signal 		= new Signal();
		private const ENDING:String 				= "ending";
		private const TRIGGER:String 				= "trigger";
		private const SPELL_SMOKE:String			= "spell_smoke";
		private const THIEF_SPELL_SMOKE:String 		= "thief_spell_smoke";
		private const JINN_TAIL_SMOKE:String		= "jinn_tail_smoke";
		private const THIEF_TAIL_SMOKE:String 		= "thief_tail_smoke";
		private const SMOKE_PATH:String 			= "scenes/arab2/shared/smoke_particle_genie.swf";
		private const THIEF_SMOKE_PATH:String 		= "scenes/arab2/shared/smoke_particle_altar.swf";
		
		private const LAMP:String 			= "an3_lamp1";
		private const MAGIC_HANDS:String 	= "an3_magichands";
		private const MAGIC_HANDS2:String 	= "an3_magichands-red";
		
		private var _hasGenie:Boolean;
		private var _hasThiefGenie:Boolean;
		private var _numberSpellTargets:Number;
		private var _numberThiefSpellTargets:Number;
		
		private var _container:DisplayObjectContainer;
		private var _smokePool:EntityPool;
		private var _lampSmokes:Vector.<Entity>;
		private var _linkedToLamp:Boolean = false;
		private var _gravityWell:GravityWell;
		public var _tailSmoke:Entity;
		
		private var _jinn:Entity;
		private var _lifetimeTail:Lifetime;
		private var _velocityTail:Velocity;
		private var _deathZoneTail:DeathZone;
		private var _fadeTail:Fade;
		private var _scaleTail:ScaleImage;
		
		public function SmokePuffGroup()
		{
			super();
		}
		
		/**
		 * @param group - parent <code>Group</code>
		 * @param container - <code>DisplayObjectContainer</code> to hold smoke
		 * @param numberJinnSmoke - <code>int</code> number of unique jinn smoke effects needed at once
		 * @param numberLampSmoke - <code>int</code> number of lamp binding smoke effects needed at once
		 */
		public function initJinnSmoke( group:Group, container:DisplayObjectContainer, numberSpellTargets:int = 1, numberThiefSpellTargets:Number = 0 ):void
		{
			this.parent = group;
			_container = container;
			
			_smokePool = new EntityPool();
			_smokePool.setSize( SPELL_SMOKE, numberSpellTargets );
			
			_hasGenie = numberSpellTargets > 0;
			_hasThiefGenie = numberThiefSpellTargets > 0;
			_numberSpellTargets = numberSpellTargets;
			_numberThiefSpellTargets = numberThiefSpellTargets;
			
			if( _hasGenie )
			{
				_smokePool.setSize( JINN_TAIL_SMOKE, 1 );
				_gravityWell = new GravityWell();
			}
			
			if( _numberSpellTargets > 0 )
			{
				parent.shellApi.loadFile( parent.shellApi.assetPrefix + SMOKE_PATH, createSpellSmoke );//Command.create( createSpellSmoke, numberSpellTargets, hasGenie, hasThiefGenie ));
			}
			else if( _numberThiefSpellTargets )
			{
				parent.shellApi.loadFile( parent.shellApi.assetPrefix + THIEF_SMOKE_PATH, Command.create( createSpellSmoke, true ));
			}
			else
			{
				smokeLoadCompleted.dispatch();
			}
		}
		
		private function createSpellSmoke( clip:DisplayObjectContainer, isThief:Boolean = false ):void//, numberSpellSmoke:int, hasGenie, hasThiefGenie ):void // createJinnSmoke
		{
			var emitter2D:Emitter2D;
			var number:int;
			var particles:SmokeParticles;
			var	smoke:Entity;
			
			var limit:Number = isThief ? _numberThiefSpellTargets : _numberSpellTargets;
			var type:String = isThief ? THIEF_SPELL_SMOKE : SPELL_SMOKE;
			var color:uint;
			
			for( number = 0; number < limit; number ++ )
			{
				particles = new SmokeParticles();
//				if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW )
//				{
//					color = type == SPELL_SMOKE ?  0x310a8a : 0x990033;
//				}
				
				smoke = EmitterCreator.create( parent, _container, particles, 0, 0, null, null, null, true );
				particles.init( parent, clip, 2, 45, 80, 1, -200, 40, false, color, false );
				
				_smokePool.release( smoke, type );
			}
			
			// MAKE THE JINN TAIL SMOKE AND LAMP LIP SMOKE
			if( !isThief && _numberThiefSpellTargets > 0 )
			{
				parent.shellApi.loadFile( parent.shellApi.assetPrefix + THIEF_SMOKE_PATH, Command.create( createSpellSmoke, true ));
			}
			if( !_hasGenie && !_hasThiefGenie )
			{
				smokeLoadCompleted.dispatch();
			}
			else
			{
				if( _hasGenie )
				{
					parent.shellApi.loadFile( parent.shellApi.assetPrefix + SMOKE_PATH, createJinnSmoke );//Command.create( createJinnSmoke, hasThiefGenie ));				
				}
				else
				{
					parent.shellApi.loadFile( parent.shellApi.assetPrefix + THIEF_SMOKE_PATH, Command.create( createJinnSmoke, true ));					
				}
			}
		}
		
		private function createJinnSmoke( clip:DisplayObjectContainer, isThief:Boolean = false ):void//, hasThiefGenie:Boolean ):void
		{
//			_lampSmokes = new Vector.<Entity>;
			setIdleValues();
			
			if( !isThief )
			{
				makeJinnSmoke( clip, JINN_TAIL_SMOKE );
			}
			else
			{
				makeJinnSmoke( clip, THIEF_TAIL_SMOKE );
			}
		}
		
		private function makeJinnSmoke( clip:DisplayObjectContainer, type:String ):void
		{
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( clip );
			var emitter2D:Emitter2D;
			emitter2D = new Emitter2D();
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 20 ));
			emitter2D.addInitializer( new Position( new EllipseZone( new Point( - bitmapData.width / 3, - bitmapData.height / 3 ), 4, 4 )));
			emitter2D.addInitializer( _lifetimeTail );
			emitter2D.addInitializer( _velocityTail );
			
			emitter2D.addAction( new Age( Back.easeInOut ));
			emitter2D.addAction( new Move());
			emitter2D.addAction( _fadeTail );
			emitter2D.addAction( _scaleTail );
			
			var	smoke:Entity = EmitterCreator.create( parent, _container, emitter2D, 0, 0, null, JINN_TAIL_SMOKE, null, true );
				
			_smokePool.release( smoke, type );
			
			if( type == JINN_TAIL_SMOKE && _hasThiefGenie )
			{
				parent.shellApi.loadFile( parent.shellApi.assetPrefix + THIEF_SMOKE_PATH, Command.create( createJinnSmoke, true ));
			}
			else
			{
				smokeLoadCompleted.dispatch();
			}
		}
		
		private function setIdleValues():void
		{
			_fadeTail = new Fade( .8, .2 );
			_lifetimeTail = new Lifetime( 1.2, 1.5 );
			_scaleTail = new ScaleImage( .4, 0 );
			_velocityTail = new Velocity( new LineZone( new Point( 0, 20 ), new Point( 0, 60 )));
		}
		
		/**
		 * Add smoke to the tail of a genie
		 */
		public function addJinnTailSmoke( jinn:Entity, isThief:Boolean = false ):void
		{
			var type:String = isThief ? THIEF_TAIL_SMOKE : JINN_TAIL_SMOKE;
			_tailSmoke = _smokePool.request( type );
			if( _tailSmoke )
			{
				var emitter2D:Emitter2D;
				var followTarget:FollowTarget = new FollowTarget( jinn.get( Spatial ));
				var tail:Entity = SkinUtils.getSkinPartEntity( jinn, SkinUtils.PANTS );
				
				if( PlatformUtils.isDesktop )
				{
					Display( tail.get( Display )).displayObject[ "tail" ].visible = false;
					
					followTarget.offset = new Point( -10, 14 );
					followTarget.allowXFlip = true;
										
					emitter2D = _tailSmoke.get( Emitter ).emitter;
					emitter2D.counter = new Random( 1, 4 );
				}
				else
				{
				//	var tailDisplay:Display = tail.get( Display );
				//	var point:Point = DisplayUtils.localToLocal( tailDisplay.displayObject[ "mobileSmoke" ], tailDisplay.displayObject );
					
					followTarget.offset = new Point( -30, 30 );
					followTarget.allowXFlip = true;
					
					emitter2D = _tailSmoke.get( Emitter ).emitter;
					emitter2D.counter = new ZeroCounter();
					_smokePool.release( _tailSmoke, type );
				}
				
				DisplayUtils.moveToOverUnder( Display( _tailSmoke.get( Display )).displayObject, Display( jinn.get( Display )).displayObject, false );
				EntityUtils.addParentChild( _tailSmoke, jinn );
				_tailSmoke.add( followTarget );
			}
		}
		
		/**
		 * @param caster - <code>Entity</code> to get the magic hands item parts and start the casting animation
		 */
		public function startSpellCasting( caster:Entity, isThief:Boolean = false ):void
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "magic_chimes.mp3", 1, true, [ SoundModifier.FADE ]);
			CharUtils.setAnim( caster, KeyboardTyping );
			var magicSparkle:String = isThief ? MAGIC_HANDS2 : MAGIC_HANDS;
			
			SkinUtils.setSkinPart( caster, SkinUtils.ITEM, magicSparkle, true );
			SkinUtils.setSkinPart( caster, SkinUtils.ITEM2, magicSparkle, true );
			
			var timeline:Timeline = caster.get( Timeline );
			if( !timeline.labelHandlers.length > 0 )
			{
				_jinn = caster;
				timeline.handleLabel( "saluteend", loopCast, false );
			}
		}
		
		private function loopCast():void
		{
			Timeline( _jinn.get( Timeline )).gotoAndPlay( "idle" );
		}
		
		public function stopSpellCasting( caster:Entity ):void
		{
			AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "magic_chimes.mp3" );//.playSoundFromEntity( caster, SoundManager.EFFECTS_PATH + "magic_chimes.mp3", 500, 0, 1, null, true );
			
			CharUtils.setAnim( caster, Stand );
			SkinUtils.emptySkinPart( caster, SkinUtils.ITEM );
			SkinUtils.emptySkinPart( caster, SkinUtils.ITEM2);
			
			var timeline:Timeline = caster.get( Timeline );
			timeline.removeLabelHandler( loopCast );
		}
		
		/**
		 * @param caster - <code>Entity</code>
		 * @param targets - <code>Vector</code> of <code>Entities</code> to cast smoke particles at
		 * @param castFunction - optional <code>Function</code> run when the cast animation is run
		 * @param endFunction - optional <code>Function</code> run after smoke clears 
		 */
		public function castSpell( caster:Entity, targets:Vector.<Entity>, castFunction:Function = null, endFunction:Function = null, longSmoke:Boolean = false, continueToCast:Boolean = false, isThief:Boolean = false ):void
		{
			var timeline:Timeline = caster.get( Timeline );
			var type:String = isThief ? THIEF_SPELL_SMOKE : SPELL_SMOKE;
			
			CharUtils.setAnim( caster, Attack, false, 0, 0, true );
			timeline.handleLabel( TRIGGER, Command.create( grantWish, caster, targets, castFunction, endFunction, longSmoke, continueToCast, type ));
			
			if( !continueToCast )
			{
				timeline.removeLabelHandler( loopCast );
				timeline.handleLabel( ENDING, Command.create( setStand, caster ));
			}
		}
		
		private function grantWish( caster:Entity, targets:Vector.<Entity>, castFunction:Function, endFunction:Function, longSmoke:Boolean = false, continueToCast:Boolean = false, type:String = null ):void
		{
			var target:Entity;
			
			for each( target in targets ) 
			{
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "poof_02.mp3" );
				var jinnSmoke:Entity = _smokePool.request( type );
				if( jinnSmoke )
				{
					if( target && target.has( Spatial ))
					{
						var spatial:Spatial = target.get( Spatial );
						var smokeSpatial:Spatial = jinnSmoke.get( Spatial );
						smokeSpatial.x = spatial.x;
						smokeSpatial.y = spatial.y;
					}
					
					jinnSmoke.add( new FollowTarget( spatial ));
					
					var smokeParticles:SmokeParticles = Emitter( jinnSmoke.get( Emitter )).emitter as SmokeParticles;
					if(longSmoke)
					{
						smokeParticles.screen();	
					}
					else
					{
						smokeParticles.puff();
					}
					
					DisplayUtils.moveToTop( Display( jinnSmoke.get( Display )).displayObject );
					
					if( endFunction )
					{
						smokeParticles.endParticle.addOnce( Command.create( handleSmoke, jinnSmoke, type ));
					}
				}
			}
			
			if( castFunction )
			{
				castFunction();
			}
			
			if( endFunction )
			{
				smokeParticles.endParticle.addOnce( endFunction );
			}
			
			if( !continueToCast )
			{
				SkinUtils.emptySkinPart( caster, SkinUtils.ITEM );
				SkinUtils.emptySkinPart( caster, SkinUtils.ITEM2 );
				
				CharUtils.setAnim( caster, Genie );
				AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "magic_chimes.mp3" );
			}
		}
		
		public function handleSmoke( jinnSmoke:Entity, type:String ):void
		{
			_smokePool.release( jinnSmoke, type );
		}
		
		private function setStand( caster:Entity ):void
		{
			CharUtils.setAnim( caster, Stand, false, 0, 0, true );
		}
		
		public function poofAt(target:Entity, duration:Number = 1, stream:Boolean = true, handler:Function = null, isThief:Boolean = false ):Entity
		{
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "poof_02.mp3" );
			var type:String = isThief ? THIEF_SPELL_SMOKE : SPELL_SMOKE;
			
			var jinnSmoke:Entity = _smokePool.request( type );
			if( jinnSmoke )
			{
				if( target && target.has( Spatial ))
				{
					var spatial:Spatial = target.get( Spatial );
					var smokeSpatial:Spatial = jinnSmoke.get( Spatial );
					smokeSpatial.x = spatial.x;
					smokeSpatial.y = spatial.y;
				}
				
				jinnSmoke.add( new FollowTarget( spatial ));
				
				var smokeParticles:SmokeParticles = Emitter( jinnSmoke.get( Emitter )).emitter as SmokeParticles;		
				if( stream )
				{
					smokeParticles.stream( duration, 25 );
				}
				else
				{
					smokeParticles.screen();
				}
				smokeParticles.endParticle.addOnce( Command.create( endParticles, jinnSmoke, type, handler ));
				
			}
			return jinnSmoke;
		}
		
		private function endParticles( jinnSmoke:Entity, type:String, handler:Function = null ):void
		{
			_smokePool.release( jinnSmoke, type );
			
			if( handler )
			{
				handler();
			}
		}
		/**
		 * @param jinn - <code>Entity</code> 
		 * @param lampHolder - <code>Entity</code> to hold the lamp and run trapping animation
		 * @param trapHandler - <code>Function</code> run after jinn linked to lamp.  If there is a dialogId, the scene function must take dialogData as a parameter
		 * @param lamp - optional <code>Entity</code> if the character is already holding the lamp, skip equiping it
		 * @param dialogId - optional <code>String</code> lampHolder dialog ID to run while trapping the jinn
		 */
		public function trapJinn( jinn:Entity, lampHolder:Entity, trapHandler:Function = null, lamp:Entity = null, dialogId:String = null ):void
		{
			var jinnSpatial:Spatial = jinn.get( Spatial );
			if( lampHolder )
			{
				var holderSpatial:Spatial = lampHolder.get( Spatial );
				
				var faceRight:Boolean = jinnSpatial.x < holderSpatial.x ? false : true;
				
				CharUtils.setDirection( lampHolder, faceRight );
				CharUtils.setDirection( jinn, !faceRight );
				if( !lamp )
				{
					SkinUtils.setSkinPart( lampHolder, SkinUtils.ITEM, LAMP, true, Command.create( readyToTrapJinn, jinn, lampHolder, trapHandler, dialogId ));
				}
				else
				{
					readyToTrapJinn( null, jinn, lampHolder, trapHandler, dialogId );
				}
			}
			else
			{
				linkJinnToLamp( jinn, null, lamp, trapHandler );
			}
		}
		
		private function readyToTrapJinn( skinPart:SkinPart, jinn:Entity, lampHolder:Entity, trapHandler:Function = null, dialogId:String = null ):void
		{
			CharUtils.setAnim( lampHolder, Sword, false, 0, 0, true );
			
			var timeline:Timeline = lampHolder.get( Timeline );
			timeline.handleLabel( "fire", Command.create( linkJinnToLamp, jinn, lampHolder ));
			
			if( dialogId )
			{
				var dialog:Dialog = lampHolder.get( Dialog );
				dialog.sayById( dialogId );
				if( trapHandler )
				{
					dialog.complete.addOnce( trapHandler );
				}
			}
		}
		
		private function linkJinnToLamp( jinn:Entity, lampHolder:Entity, lamp:Entity = null, trapHandler:Function = null ):void
		{
			_linkedToLamp = true;
			
			if( lampHolder && !lamp )
			{
				var timeline:Timeline = lampHolder.get( Timeline );
				timeline.stop();
				
				lamp = SkinUtils.getSkinPartEntity( lampHolder, SkinUtils.ITEM );
			}
			else
			{
				trapHandler();
			}
			
			var eyeballDatum:EyeBallData;
			var eyeEntity:Entity = SkinUtils.getSkinPartEntity( jinn, SkinUtils.EYES );
			var eyeballData:Vector.<EyeBallData> = new <EyeBallData>[ eyeEntity.get( Eyes ).eye1, eyeEntity.get( Eyes ).eye2 ];
			
			for each( eyeballDatum in eyeballData )
			{
				if( Id( jinn.get( Id )).id == "genieThief" )
				{
					eyeballDatum.pupil.transform.colorTransform = new ColorTransform( 1, 1, 1, 1, 175, 0, 80 );
				}
				else
				{
					eyeballDatum.pupil.transform.colorTransform = new ColorTransform( 1, 1, 1, 1, 0, 92, 204 );					
				}
			}
			
			linkSmokeToLamp( jinn, lamp );
			
			SkinUtils.setEyeStates( jinn, EyeSystem.SQUINT, EyeSystem.FRONT );
			SkinUtils.setSkinPart( jinn, SkinUtils.MOUTH, "greekwarrior" );
			
			CharUtils.setAnim( jinn, Genie, false, 0, 0, true );
			timeline = jinn.get( Timeline );
			timeline.handleLabel( "saluteend", Command.create( jinnIdleHandler, jinn ), false );
		}
		
		private function jinnIdleHandler( jinn:Entity ):void
		{
			var timeline:Timeline = jinn.get( Timeline );
			if( _linkedToLamp )
			{
				timeline.gotoAndPlay( "idle" );
			}
			else
			{
				timeline.removeLabelHandler( jinnIdleHandler );
			}
		}
		
		private function linkSmokeToLamp( jinn:Entity, lamp:Entity, isThief:Boolean = false ):void
		{
			var lampLip:MovieClip = Display( lamp.get( Display )).displayObject[ "lip" ];
			var lampPoint:Point = DisplayUtils.localToLocal( lampLip, _container );
			var rate:Number = 20;
			
			if( !PlatformUtils.isDesktop )
			{
				var type:String = isThief ? THIEF_TAIL_SMOKE : JINN_TAIL_SMOKE;
				_tailSmoke = _smokePool.request( type );
				rate = 10;
			}
			// JINN TAIL
			if( _tailSmoke )
			{
				var emitter2D:Emitter2D = _tailSmoke.get( Emitter ).emitter;
				var spatial:Spatial = _tailSmoke.get( Spatial );
					
				var x:Number =	Math.abs( lampPoint.x - spatial.x );
				var x2:Number = x * x;
				var y:Number = Math.abs( lampPoint.y - spatial.y );
				var y2:Number = y * y;
					
				_gravityWell.power = ( x2 + y2 ) / 50; 
				_gravityWell.x = lampPoint.x;
				_gravityWell.y = lampPoint.y;
				
				emitter2D.addAction( _gravityWell );
				emitter2D.counter = new Steady( rate );
				
				// ADJUST THE VELOCITY
				emitter2D.removeInitializer( _lifetimeTail );
				emitter2D.removeInitializer( _velocityTail );
				emitter2D.removeAction( _fadeTail );
				emitter2D.removeAction( _scaleTail );
				
				_lifetimeTail = new Lifetime( 1.2, 1.5 );
				_velocityTail =  new Velocity( new LineZone( new Point( 0, 0 ), new Point(( lampPoint.x - spatial.x ) / 2, ( lampPoint.y - spatial.y ) / 2 )));
				_deathZoneTail = new DeathZone( new RectangleZone( spatial.x - lampPoint.x, spatial.y - 100, spatial.x, lampPoint.y ), true );
				_fadeTail = new Fade( .5, .4 );
				
				if( PlatformUtils.isDesktop )
				{
					_scaleTail = new ScaleImage( .4, .2 );
				}
				else
				{
					_scaleTail = new ScaleImage( .2, .1 );
				}
				
				emitter2D.addInitializer( _lifetimeTail );
				emitter2D.addInitializer( _velocityTail );
				emitter2D.addAction( _deathZoneTail );
				emitter2D.addAction( _fadeTail );
				emitter2D.addAction( _scaleTail );
			}
		}
		
		public function releaseJinn( jinn:Entity, isThief:Boolean = false ):void
		{
			var eyeballDatum:EyeBallData;
			var eyeEntity:Entity = SkinUtils.getSkinPartEntity( jinn, SkinUtils.EYES );
			var eyeballData:Vector.<EyeBallData> = new <EyeBallData>[ eyeEntity.get( Eyes ).eye1, eyeEntity.get( Eyes ).eye2 ];
			
			for each( eyeballDatum in eyeballData )
			{
				eyeballDatum.pupil.transform.colorTransform = new ColorTransform( 1, 1, 1, 1, 0, 0, 0 );
			}
			
			if( _tailSmoke )
			{
				var type:String = isThief ? THIEF_TAIL_SMOKE : JINN_TAIL_SMOKE;
				_tailSmoke.remove( Parent );
				
				_smokePool.release( _tailSmoke, type );
				_tailSmoke = null;
			}
			
			_linkedToLamp = false;
		}
		
		/**
		 * Releases all smoke emitter entities back into the smoke pool
		 */
		public function removeLampSmokes( isThief:Boolean = false, stopGenie:Boolean = false ):void
		{			
			if( _tailSmoke )
			{
				var emitter2D:Emitter2D = _tailSmoke.get( Emitter ).emitter;
				
				emitter2D.removeAction( _gravityWell );
				emitter2D.removeInitializer( _velocityTail );
				emitter2D.removeInitializer( _lifetimeTail );
				emitter2D.removeAction( _fadeTail );
				emitter2D.removeAction( _scaleTail );
				emitter2D.removeAction( _deathZoneTail );
				
				setIdleValues();
				
				emitter2D.addInitializer( _velocityTail );
				emitter2D.addInitializer( _lifetimeTail );
				emitter2D.addAction( _fadeTail );
				emitter2D.addAction( _scaleTail );
				
				if( !PlatformUtils.isDesktop || stopGenie )
				{
					var type:String = isThief ? THIEF_TAIL_SMOKE : JINN_TAIL_SMOKE;
					_tailSmoke.remove( Parent );
					emitter2D.counter = new ZeroCounter();
					
					_smokePool.release( _tailSmoke, type );
					_tailSmoke = null;
				}
			}
		}
	}
}