package game.scenes.backlot.cityDestroy
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	
	import game.components.motion.Edge;
	import game.components.motion.WaveMotion;
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.entity.DepthChecker;
	import game.components.timeline.Timeline;
	import game.components.entity.collider.PlatformCollider;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.ui.ToolTip;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.scenes.backlot.BacklotEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.cityDestroy.components.BalloonComponent;
	import game.scenes.backlot.cityDestroy.components.CannonComponent;
	import game.scenes.backlot.cityDestroy.components.CannonShotHit;
	import game.scenes.backlot.cityDestroy.components.Health;
	import game.scenes.backlot.cityDestroy.components.JetComponent;
	import game.scenes.backlot.cityDestroy.components.SearchLightComponent;
	import game.scenes.backlot.cityDestroy.components.SoldierComponent;
	import game.scenes.backlot.cityDestroy.components.SoldierHit;
	import game.scenes.backlot.cityDestroy.systems.BalloonSystem;
	import game.scenes.backlot.cityDestroy.systems.CannonShotHitSystem;
	import game.scenes.backlot.cityDestroy.systems.CannonShotSystem;
	import game.scenes.backlot.cityDestroy.systems.CannonSystem;
	import game.scenes.backlot.cityDestroy.systems.HealthSystem;
	import game.scenes.backlot.cityDestroy.systems.JetSystem;
	import game.scenes.backlot.cityDestroy.systems.SearchLightSystem;
	import game.scenes.backlot.cityDestroy.systems.SoldierHitSystem;
	import game.scenes.backlot.cityDestroy.systems.SoldierSystem;
	import game.scenes.backlot.shared.popups.Clapboard;
	import game.scenes.backlot.soundStage4.SoundStage4;
	import game.systems.SystemPriorities;
	import game.systems.motion.WaveMotionSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class CityDestroy extends PlatformerGameScene
	{
		public function CityDestroy()
		{
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/backlot/cityDestroy/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			putOnCostume();
			
			super.loaded();
			_events = super.events as BacklotEvents;	
			
			setupObstacles();
			super.loadFile( "overlay.swf", addHud );
			player.remove( DepthChecker );
			player.add(new CannonShotHit());
			player.add(new SoldierHit());
			
			super.addSystem( new BalloonSystem(), SystemPriorities.resolveCollisions );
			super.addSystem( new CannonShotSystem(), SystemPriorities.resolveCollisions );
			super.addSystem( new CannonSystem( _hitContainer ), SystemPriorities.resolveCollisions );
			super.addSystem( new JetSystem( _hitContainer ), SystemPriorities.resolveCollisions );
			super.addSystem( new SearchLightSystem(), SystemPriorities.resolveCollisions );
			super.addSystem( new SoldierSystem(), SystemPriorities.resolveCollisions );
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			super.addSystem( new WaveMotionSystem(), SystemPriorities.move );
			super.addSystem( new CannonShotHitSystem(), SystemPriorities.resolveCollisions );
			super.addSystem( new SoldierHitSystem(), SystemPriorities.resolveCollisions );
			super.addSystem( new HealthSystem(), SystemPriorities.render );
		}
		
		private var takes:int = 0;
		
		/*******************************
		 *    	   SETUP SCENE
		 * *****************************/
		private function putOnCostume():void
		{
			var lookAspect:LookAspectData;
			var lookData:LookData = new LookData();
			
			lookAspect = new LookAspectData( SkinUtils.MOUTH, 5 );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.MARKS, "shadow1" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.FACIAL, "bl_gorilla" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.HAIR, "hobo" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.SHIRT, "hobo" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.PANTS, "spanishcon" );
			lookData.applyAspect( lookAspect );
			lookAspect = new LookAspectData( SkinUtils.OVERSHIRT, "bl_gorilla" );
			lookData.applyAspect( lookAspect );
			
			SkinUtils.applyLook( player, lookData, false );
					
			var spatial:Spatial = player.get( Spatial );
			spatial.scale = .72;
			var edge:Edge = player.get( Edge );
			edge.rectangle.x *= 2;
			edge.rectangle.y *= 2;
			edge.rectangle.width *= 2;
			edge.rectangle.height *= 2;
		}
		
		private function setupObstacles():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var spatial:Spatial;
			var toolTipEntity:Entity;
			var number:int;
			var beam:Entity;
			var base:Entity;
			var explosion:Entity;
			var motion:Motion;
			var timeline:Timeline;
			var wave:WaveMotion;
			var waveData:WaveMotionData
			var threshold:Threshold;
			
			var balloon:BalloonComponent;
			var cannon:CannonComponent;
			var jet:JetComponent;
			var light:SearchLightComponent;
			var soldier:SoldierComponent;
			
			var temp:int;
			
			var audioRange:AudioRange = new AudioRange(1000,.01,1,Quad.easeIn);

			balloons = new Vector.<BalloonComponent>();
			// BALLOONS
			for( number = 0; number < 7; number ++ )
			{
				balloon = new BalloonComponent();
				balloon.pop.add(collectBalloon);
				
				clip = _hitContainer[ "balloon" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add(new Audio()).add( new Id( "balloon" + number ));
				
				balloon.rope = EntityUtils.createSpatialEntity( this, clip.rope );
				TimelineUtils.convertClip( clip.rope, this, balloon.rope, entity );
				
				balloon.balloon = EntityUtils.createSpatialEntity( this, clip.balloon );
				TimelineUtils.convertClip( clip.balloon, this, balloon.balloon, entity );
				
				balloon.hit = clip.hit;
				balloon.number = number;
				
				wave = new WaveMotion();
				waveData = new WaveMotionData( "y", 3, Math.ceil( Math.random() * 4 ) * .05 );
				wave.data.push( waveData );
				
				entity.add( balloon ).add( wave ).add( new SpatialAddition());
				balloons.push(balloon);
			}
			
			// GOAL BALLOON
			balloon = new BalloonComponent();
			balloon.pop.add(collectBalloon);
			clip = _hitContainer[ "goal" ];
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add(new Audio()).add( new Id( "goal" ));
			
			balloon.rope = EntityUtils.createSpatialEntity( this, clip.rope );
			TimelineUtils.convertClip( clip.rope, this, balloon.rope, entity );
			
			balloon.balloon = EntityUtils.createSpatialEntity( this, clip.balloon );
			TimelineUtils.convertClip( clip.balloon, this, balloon.balloon, entity );
			
			balloon.hit = clip.hit;
			balloon.ropeEmpty = _hitContainer[ "stringEmpty" ];
			balloon.number = 7;
			
			wave = new WaveMotion();
			waveData = new WaveMotionData( "y", 3, Math.ceil( Math.random() * 4 ) * .05 );
			wave.data.push( waveData );
			
			entity.add( balloon ).add( wave ).add( new SpatialAddition());
			balloons.push(balloon);
			
			// CANNONS
			for( number = 0; number < 3; number ++ )
			{
				cannon = new CannonComponent();
				
				clip = _hitContainer[ "cannon" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				
				entity.add(new Audio()).add(audioRange).add( new Id( "cannon" + number ));
				
				cannon.hit = clip.hit;
				cannon.shellUrl = super.shellApi.assetPrefix + this.groupPrefix + "cannonShell.swf";
				
				cannon.barrel = EntityUtils.createMovingEntity( this, clip.barrel );
				TimelineUtils.convertClip( clip.barrel, this, cannon.barrel );
				timeline = cannon.barrel.get( Timeline );
				timeline.paused = true;
				
				cannon.shotEmpty = clip.barrel.shotEmpty;
				
				cannon.explosion = EntityUtils.createSpatialEntity( this, clip.explosion );
				TimelineUtils.convertClip( clip.explosion, this, cannon.explosion );
				timeline = cannon.explosion.get( Timeline );
				timeline.paused = true;
				Display( cannon.explosion.get( Display )).visible = false;
				
				cannon.base = EntityUtils.createSpatialEntity( this, clip.base );
				TimelineUtils.convertClip( clip.base, this, cannon.base );
				timeline = cannon.base.get( Timeline );
				timeline.paused = true;
				
				entity.add( cannon );
			}
			
			// JETS
			for( number = 0; number < 7; number ++ ) 
			{
				jet = new JetComponent();
				threshold = new Threshold( "x" );
				
				clip = _hitContainer[ "plane" + number ];
				
				entity = EntityUtils.createMovingEntity( this, clip );
				entity.add(new Audio()).add(audioRange).add( new Id( "jet" + number ));
				spatial = entity.get( Spatial );
				
				jet.hit = clip.hit;
				jet.shellUrl = super.shellApi.assetPrefix + this.groupPrefix + "planeShell.swf";
				
				jet.explosion = EntityUtils.createSpatialEntity( this, clip.explosion );
				TimelineUtils.convertClip( clip.explosion, this, jet.explosion );
				timeline = jet.explosion.get( Timeline );
				timeline.paused = true;
				Display( jet.explosion.get( Display )).visible = false;
				
				jet.propellor = EntityUtils.createSpatialEntity( this, clip.prop );
				TimelineUtils.convertClip( clip.prop, this, jet.propellor );			
				
				temp = Math.abs( Math.random());
				
				if( temp > 0 )
				{
					jet.movingLeft = true;
				}
				jet.level = spatial.y;

				entity.add( jet ).add( threshold ).add( new Tween());
			}
			
			// LIGHTS
			for( number = 0; number < 12; number ++ )
			{
				light = new SearchLightComponent();
				clip = _hitContainer[ "light" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip);
				entity.add( new Audio()).add( new Id( "light" + number ));
				
				light.beam = EntityUtils.createMovingEntity( this, clip.beam );
				light.hit = clip.hit;
				
				light.explosion = EntityUtils.createSpatialEntity( this, clip.explosion );
				TimelineUtils.convertClip( clip.explosion, this, light.explosion );
				timeline = light.explosion.get( Timeline );
				timeline.paused = true;
				Display( light.explosion.get( Display )).visible = false;
				
				light.base = EntityUtils.createSpatialEntity( this, clip.base );
				TimelineUtils.convertClip( clip.base, this, light.base );
				timeline = light.base.get( Timeline );
				timeline.paused = true;
				
				entity.add( light );
			}
			
			// SOLDIERS
			for( number = 0; number < 6; number ++ )
			{
				soldier = new SoldierComponent();
				entity = super.getEntityById( "army" + number );
				spatial = entity.get( Spatial );
				///*
				//toolTipEntity = Children( entity.get( Children )).children[ 0 ];
				//toolTipEntity.remove( ToolTip );
				ToolTipCreator.addToEntity(entity, ToolTipType.NAVIGATION_ARROW);
				entity.remove( Interaction );
				entity.remove( SceneInteraction );
				//super.removeEntity( entity.get( Children ).children[ 0 ]);
				//entity.remove( Children );
				
				if( number < 1 )
				{
					soldier.pointA = new Point( 610, spatial.y );
					soldier.pointB = new Point( 890, spatial.y );
				}
				else if( number < 2 )
				{
					soldier.pointA = new Point( 270, spatial.y );
					soldier.pointB = new Point( 560, spatial.y );
				}
				else if( number < 3 )
				{
					soldier.pointA = new Point( 660, spatial.y );
					soldier.pointB = new Point( 890, spatial.y );
				}
				else
				{
					soldier.pointA = new Point( 70, spatial.y );
					soldier.pointB = new Point( 350, spatial.y );
				}
				//*/
				entity.add(new Audio()).add(audioRange).add( soldier );
				
			}
			
			// DAMSEL
			entity = super.getEntityById( "damsel" );
			toolTipEntity = Children( entity.get( Children )).children[ 0 ];
			toolTipEntity.remove( ToolTip );
			entity.remove( Interaction );
			entity.remove( SceneInteraction );
			
			menu = super.addChildGroup( new CityDestroyMenu(START, super.overlayContainer )) as CityDestroyMenu;
			//menu.clickedOk.add(start);
			/*
			if(shellApi.profileManager.active.userFields[shellApi.island] != null)
			{
				if(shellApi.profileManager.active.userFields[shellApi.island]["stage4"] != null)
					takes = shellApi.getUserField("stage4",shellApi.island, true);
				else
					saveTakesToServer();
			}
			else
			{
				saveTakesToServer();
			}
			*/
		}
		
		private function start():void
		{
			takes++;
			saveTakesToServer();
			
			var clapboard:Clapboard = new Clapboard(this.overlayContainer,4,takes);
			this.addChildGroup(clapboard);
		}
		
		private function saveTakesToServer():void
		{
			shellApi.setUserField("stage4", takes,shellApi.island,true);
		}
		
		public function collectBalloon( balloon:int ):void
		{
			if(balloon == 7)
			{
				for(var i:int = 0; i < balloons.length - 1; i++)
				{
					if(!balloons[i].popped)
					{
						menu = super.addChildGroup( new CityDestroyMenu(WRONG,  super.overlayContainer )) as CityDestroyMenu;
						menu.clickedOk.add(restart);
						return;
					}
				}
				menu = super.addChildGroup( new CityDestroyMenu(REACHED_TOP,  super.overlayContainer )) as CityDestroyMenu;
				completeScene = true;
			}
		}
		
		private function win():void
		{
			addSystem( new ThresholdSystem(), SystemPriorities.update );
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = shellApi.camera.camera.areaHeight - 250;
			threshold.entered.add(bounce);
			player.add(threshold);
			player.remove(PlatformCollider);
			Motion(player.get(Motion)).acceleration.y = 10000;
			Motion(player.get(Motion)).rotationVelocity = 50;
			player.remove(CannonShotHit);
			player.remove(SoldierHit);
			FSMControl(player.get(FSMControl)).setState(CharacterState.HURT);
			SceneUtil.addTimedEvent(this, new TimedEvent(3,1,completeStage));
		}
		
		private function bounce():void
		{
			Motion(player.get(Motion)).acceleration.y = 500;
			Motion(player.get(Motion)).velocity.y = -10000;
		}
		
		private function completeStage():void
		{
			shellApi.completeEvent(_events.COMPLETE_STAGE_4);
			shellApi.loadScene(SoundStage4);
		}
		
		/*******************************
		 *    	    SETUP HUD
		 * *****************************/
		private function addHud( asset:MovieClip ):void
		{
			super.overlayContainer.addChild( asset.contents );
			
			var clip:MovieClip;
			var spatial:Spatial;
			var entity:Entity;
			var timeline:Timeline;
			var number:int;
			
			entity = EntityUtils.createSpatialEntity( this, asset.contents.life.bar );
			entity.add( new Id( "lifeBar" ));
			spatial = entity.get( Spatial );
			spatial.scaleX = 140;
			
			player.add(new Health(50,entity,true, new Point(140,1)));
			Health(player.get(Health)).died.add(dead);
			
			for( number = 0; number < 8; number ++ )
			{
				clip = MovieClip( asset.contents.balloons ).getChildByName( "point" + number ) as MovieClip;
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "point" + number ));
				
				TimelineUtils.convertClip( clip, this, entity );
				timeline = entity.get( Timeline );
				timeline.paused = true;
			}
		}
		
		private function dead():void
		{
			// should bring up a menu first saying you died or won
			if(completeScene)
			{
				menu = super.addChildGroup( new CityDestroyMenu(WON,  super.overlayContainer )) as CityDestroyMenu;
				menu.clickedOk.add(win);
				return;
			}
			
			menu = super.addChildGroup( new CityDestroyMenu(DIED,  super.overlayContainer )) as CityDestroyMenu;
			menu.clickedOk.add(restart);
		}
		
		private function restart():void
		{
			shellApi.loadScene(CityDestroy, 450, 2413 );
		}
		
		private const REACHED_TOP:String = "reached_top.swf";
		private const DIED:String = "died.swf";
		private const START:String = "start.swf";
		private const WON:String = "won.swf";
		private const WRONG:String = "wrong.swf";
		
		private var completeScene:Boolean;
		private var menu:CityDestroyMenu;
		private var balloons:Vector.<BalloonComponent>;
		private var _events:BacklotEvents;
	}
}