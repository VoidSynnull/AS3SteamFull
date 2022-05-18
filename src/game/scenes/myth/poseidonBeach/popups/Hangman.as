package game.scenes.myth.poseidonBeach.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Sleep;
	import game.components.motion.ShakeMotion;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	import org.osflash.signals.Signal;
	
	public class Hangman extends Popup
	{
		public function Hangman( container:DisplayObjectContainer=null )
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// do any cleanup required in this Group before calling the super classes destroy method
			complete.removeAll();
			complete = null;
			
			fail.removeAll();
			fail = null;
			
			_nameLength = null;
			_godList = null;
			_letters = null;
			
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			complete = new Signal();
			fail = new Signal();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/poseidonBeach/";
			super.init( container );
			load();
		}		
		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void{
			SceneUtil.lockInput(parent,false);
			super.close(removeOnClose,onClosedHandler);
		}
		override public function load():void
		{
			super.loadFiles([ "hangman.swf" ], false, true, loaded );
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset( "hangman.swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
			
			var pillar:DisplayObjectContainer = screen.content.pillar;			
			pillar.y = super.shellApi.viewportHeight - pillar.height;
			
			loadCloseButton();
			
			_godList.push( ARES, HERMES, APHRODITE, ARTEMIS, HESTIA, APOLLO );
			_letters.push( "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z" );
			
			setupHangman();
			
			super.loaded();
		}
		
		private function setupHangman():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var timeline:Timeline;
			var number:int;
			
			// Letters
			for( number = 1; number < 27; number ++ )
			{
				clip =  MovieClip( MovieClip( super.screen.content ).getChildByName( "btn" + number ));
				
				entity = ButtonCreator.createButtonEntity( clip, this, addLetter );
				
				timeline = entity.get( Timeline );
				timeline.paused = true;
				
				entity.add( new Id( _letters[ number - 1 ] ));
			}
			
			// Hearts
			for( number = 0; number < 3; number ++ )
			{
				clip = MovieClip( MovieClip( super.screen.content.pillar ).getChildByName( "heart" + number ));
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "heart" + number ));
				
				TimelineUtils.convertClip( clip, this, entity );
				timeline = entity.get( Timeline );
				timeline.paused = true;
			}
			
			// Statue
			clip = MovieClip( MovieClip( super.screen.content.pillar ).getChildByName( "statue" ));
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( "statue" ));
			
			TimelineUtils.convertClip( clip, this, entity );
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( 0 );
			Sleep( entity.get( Sleep )).ignoreOffscreenSleep = true;			
			
			// Question text
			clip = MovieClip( MovieClip( super.screen.content ).getChildByName( "question" ));
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( "question" ));
			
			TimelineUtils.convertClip( clip, this, entity );
			timeline = entity.get( Timeline );
			timeline.paused = true;
						
			// God names
			setGod( ARES, 0 );
			setGod( HERMES, 1 );
			setGod( APHRODITE, 2 );
			setGod( ARTEMIS, 3 );
			setGod( HESTIA, 4 );
			setGod( APOLLO, 5 );
			
			Display( super.getEntityById( ARES ).get( Display )).visible = true;
		}
		
		private function setGod( name:String, placement:int ):void
		{
			var number:int;
			var letter:String;
			var clip:MovieClip;
			var entity:Entity;
			
			// create letter entities for each god
			for( number = 0; number < name.length; number ++ )
			{
				letter = name.charAt( number );
				clip = MovieClip( MovieClip( MovieClip( super.screen.content ).getChildByName( name )).getChildByName( "letter" + number ));
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "god" + placement + "letter" + number ));
				Display( entity.get( Display )).visible = false;
			}
			
			// create the name entity for each god and hide it
			clip = MovieClip( MovieClip( super.screen.content ).getChildByName( name ));
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( name ));
			Display( entity.get( Display )).visible = false;
			
			_nameLength.push( name.length );
		}
		
		private function addLetter( button:Entity ):void
		{
			if( !locked )
			{
				button.get(Interaction).lock = true;
				var correct:Boolean = false;
				var guess:String = button.get( Id ).id;
				var timeline:Timeline = button.get( Timeline );
				var entity:Entity;
				
				if( timeline.currentIndex < 1 )
				{
					timeline.gotoAndStop( 1 );
					
					for( var number:int = 0; number < _godList[ _godCount ].length; number ++ )
					{
						if( _godList[ _godCount ].charAt( number ) == guess )
						{
							correct = true;
							
							super.shellApi.triggerEvent( "correct_god" );
							entity = super.getEntityById( "god" + _godCount + "letter" + number );
							Display( entity.get( Display )).visible = true;
							
							_correctLetters ++;
						}
					}
				
					if( !correct )
					{
						
						if( _miss >= 3 )
						{
							locked = true;
							SceneUtil.lockInput( this, locked );
							failed();
						}
						else
						{	
							super.shellApi.triggerEvent( "break_heart" );
							timeline = super.getEntityById( "heart" + _miss ).get( Timeline );
							timeline.gotoAndStop( 1 );
							_miss ++;
						}
					}
				}
							
				if( _correctLetters == _nameLength[ _godCount ])
				{
					locked = true;
					SceneUtil.lockInput( this, locked );
					correctName();
				}
			}
		}
		
		private function correctName():void
		{
			var entity:Entity;
			var interaction:Interaction;
			var number:int;
			
			for( number = 1; number < 27; number ++ )
			{
				entity = super.getEntityById( _letters[ number - 1 ]);
				entity.get( Interaction ).lock = true;
			}
			
			if( _godCount < 5 )
			{
				switchGods();
			}
			else
			{
				SceneUtil.delay( this, 1, completeHangman );
			}
		}
		
		private function switchGods():void
		{
			var entity:Entity;
			var interaction:Interaction;
			var number:int;
		
			entity = super.getEntityById( "statue" );
			var shake:ShakeMotion = new ShakeMotion( new RectangleZone( -10, -2, 10, 2 ));
			entity.add( shake );
			
			downSmoke();
			shakeStatue( 15, entity );
			ShakeMotionSystem( super.addSystem( new ShakeMotionSystem() )).configEntity( entity );
			
			super.shellApi.triggerEvent( "next_statue" );
		}
		
		private function shakeStatue( counter:int, entity:Entity ):void
		{
			var shake:ShakeMotion = entity.get( ShakeMotion );
			var newCount:int = counter - 1;
			var smoke:Entity = super.getEntityById( "smokeEmitter" );
			var emitter:Emitter2D = smoke.get( Emitter ).emitter;
						
			if ( counter > 0 )
			{
				emitter.counter = new Random( newCount, newCount + 10 );
				SceneUtil.addTimedEvent( this, new TimedEvent( .04, 1, Command.create( shakeStatue, newCount, entity )));
			}
			else
			{
				shake.shakeZone = new RectangleZone( 0, 0, 0, 0 );
				SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( downTween, entity )));
			}
		}
					
		private function downTween( entity:Entity ):void
		{
			var tween:Tween;
			
			if( !entity.get( Tween ))
			{
				tween = new Tween();
				entity.add( tween );
			}
			else
			{
				tween = entity.get( Tween );
			}
			
			var spatial:Spatial = entity.get( Spatial );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.2, 1, stopSmoke ));
			tween.to( spatial, 2, { y : spatial.y + 400, onComplete : Command.create( resetBoard, entity )});
		}
		
		private function downSmoke():void
		{
			var emitter:Emitter2D ;
			var smoke:Entity = super.getEntityById( "smokeEmitter" );
			if( !smoke )
			{
//				super.removeEntity( super.getEntityById( "smokeEmitter" ) );
//			}
			
				emitter = new Emitter2D();
				
				emitter.counter = new Random( 50, 60 );
				emitter.addInitializer( new ImageClass( Blob, [10, 0xEEEEEE], true ) );
				emitter.addInitializer( new AlphaInit( .6, .7 ));
				emitter.addInitializer( new Lifetime( .5, 1 )); 
				emitter.addInitializer( new Velocity( new LineZone( new Point( -75, -10), new Point( 75, -15 ))));
				emitter.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 50, 2 )));
				
				emitter.addAction( new Age( Quadratic.easeOut ));
				emitter.addAction( new Move());
				emitter.addAction( new RandomDrift( 100, 100 ));
				emitter.addAction( new ScaleImage( .7, 1.5 ));
				emitter.addAction( new Fade( .7, 0 ));
				emitter.addAction( new Accelerate( 0, -10 ));
				
				EmitterCreator.create( this, MovieClip( MovieClip( super.screen.content.pillar ).getChildByName( "smokeEmpty" )), emitter, 0, 0, null, "smokeEmitter" );
			}
			else
			{
				emitter = smoke.get( Emitter ).emitter;
				emitter.counter = new Random( 11, 21 );
			}
		}
			
		private function upTween( entity:Entity ):void
		{
			var tween:Tween = entity.get( Tween );
			
			var timeline:Timeline = entity.get( Timeline );
			timeline.nextFrame();
			timeline.gotoAndStop( timeline.nextIndex );
			
			var spatial:Spatial = entity.get( Spatial );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.4, 1, upSmoke ));
			SceneUtil.addTimedEvent( this, new TimedEvent( 2.5, 1, stopSmoke ));
			tween.to( spatial, 2, { y : spatial.y - 400, onComplete : unlock });
			
//			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, unlock ));
			super.shellApi.triggerEvent( "next_statue" );
		}
		
		private function upSmoke():void
		{
			var emitter:Emitter2D ;
			var smoke:Entity = super.getEntityById( "smokeEmitter" );
			if( !smoke )
			{
//				super.removeEntity( super.getEntityById( "smokeEmitter" ) );
//			}
			
				emitter = new Emitter2D();
				
				emitter.counter = new Random( 11, 21 );
				emitter.addInitializer( new ImageClass( Blob, [10, 0xEEEEEE], true ) );
				emitter.addInitializer( new AlphaInit( .6, .7 ));
				emitter.addInitializer( new Lifetime( .5, 1 )); 
				emitter.addInitializer( new Velocity( new LineZone( new Point( -100, -1), new Point( 100, -5 ))));
				emitter.addInitializer( new Position( new EllipseZone( new Point( 0, 0 ), 50, 2 )));
				
				emitter.addAction( new Age( Quadratic.easeOut ));
				emitter.addAction( new Move());
				emitter.addAction( new RandomDrift( 100, 100 ));
				emitter.addAction( new ScaleImage( .7, 1.5 ));
				emitter.addAction( new Fade( .7, 0 ));
				emitter.addAction( new Accelerate( 0, -10 ));
				
				EmitterCreator.create( this, MovieClip( MovieClip( super.screen.content.pillar ).getChildByName( "smokeEmpty" )), emitter, 0, 0, null, "smokeEmitter" );
			}
			else
			{
				emitter = smoke.get( Emitter ).emitter;
				emitter.counter = new Random( 11, 21 );
			}
		}
		
		private function stopSmoke( ):void
		{
			var smoke:Entity = super.getEntityById( "smokeEmitter" );
			var emitter:Emitter2D = smoke.get( Emitter ).emitter;
			
			emitter.counter = new Random( 0, 0 );
		}
		
		private function resetBoard( entity:Entity ):void
		{
			var interaction:Interaction;
			var number:int;
			var timeline:Timeline;
						
			entity = super.getEntityById( _godList[ _godCount ]);
			Display( entity.get( Display )).visible = false;
			
			_godCount ++;
			
			// change current god
			entity = super.getEntityById( _godList[ _godCount ]);
			Display( entity.get( Display )).visible = true;
			
			_correctLetters = 0;
			
			// reset hearts
			for( number = 0; number < 3; number ++ )
			{
				entity = super.getEntityById( "heart" + number );
				timeline = entity.get( Timeline );
				timeline.gotoAndStop( 0 );
			}
			_miss = 0;
			
			// set question to correct gender
			entity = super.getEntityById( "question" );
			timeline = entity.get( Timeline );
			
			if( _godCount >= 2 && _godCount < 5 )
			{
				timeline.gotoAndStop( 1 );
			}
			else
			{
				timeline.gotoAndStop( 0 );
			}
			
			// reset letter baord
			for( number = 1; number < 27; number ++ )
			{
				entity = super.getEntityById( _letters[ number - 1 ]);
				timeline = entity.get( Timeline );
				timeline.gotoAndStop( 0 );
				
				entity.get(Interaction).lock = false;
			}
			
			// tween in new god
			entity = super.getEntityById( "statue" );
			upTween( entity );
		}
		
		private function unlock():void
		{
			locked = false;
			SceneUtil.lockInput( this, locked );
		}
		
		private function failed():void
		{
			var entity:Entity;
			var interaction:Interaction;
			var number:int;
			
			for( number = 1; number < 27; number ++ )
			{
				entity = super.getEntityById( _letters[ number - 1 ]);
				interaction = entity.get( Interaction );
				interaction.removeAll();
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, failHangman ));
		}
		
		private function failHangman():void
		{
			fail.dispatch();
		}
		
		private function completeHangman():void
		{
			locked = true;
			SceneUtil.lockInput( this, locked );
			complete.dispatch();
		}
		
		public var complete:Signal;
		public var fail:Signal;
		
		private var locked:Boolean = false;
		
		private static const ARES:String = "ARES";
		private static const HERMES:String = "HERMES";
		private static const APHRODITE:String = "APHRODITE";
		private static const ARTEMIS:String = "ARTEMIS";
		private static const HESTIA:String = "HESTIA";
		private static const APOLLO:String = "APOLLO";
		private var _correctLetters:uint = 0;
		private var _nameLength:Vector.<int> = new Vector.<int>;
		private var _godList:Vector.<String> = new Vector.<String>;
		private var _letters:Vector.<String> = new Vector.<String>;
		
		private var _miss:uint = 0;
		private var _godCount:uint = 0;
	}
}