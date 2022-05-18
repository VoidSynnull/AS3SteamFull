package game.scenes.ghd.barren1
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Door;
	import game.components.hit.Hazard;
	import game.components.hit.SceneObjectHit;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.data.profile.ProfileData;
	import game.scene.template.AudioGroup;
	import game.scenes.deepDive2.predatorArea.particles.GlassParticles;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.shared.fallingRocks.Meteor;
	import game.scenes.ghd.shared.fallingRocks.MeteorHitRock;
	import game.scenes.ghd.shared.fallingRocks.MeteorSystem;
	import game.scenes.ghd.shared.groundShadows.GroundShadow;
	import game.scenes.ghd.shared.groundShadows.GroundShadowSystem;
	import game.systems.scene.DoorSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	
	import org.flintparticles.common.initializers.Lifetime;
	import org.osflash.signals.Signal;
	
	public class Barren1 extends GalacticHotDogScene
	{
		private var _meteorSystem:MeteorSystem;
		
		private var _meteor:Entity;
		private var _shadow:Entity;
		
		private var targetRadius:Number = 200;
		
		private var _shadowSystem:GroundShadowSystem;
		
		private var _doorSys:DoorSystem;
		
		private var _profile:ProfileData;
		private var _rockData:Array;
		
		private const FALL_SOUND:String = SoundManager.EFFECTS_PATH + "object_fall_01.mp3";
		
		public function Barren1()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/barren1/";
			//showHits = true;
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			
			super.load();
		}
		
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "resetRocksPlz")
			{
				if(!_profile){
					_profile = shellApi.profileManager.active;
				}
				_rockData = [0,1,2,3,4,5,6];
				// NOTE :: this will only store the rocks locally, they will not be stored on the server. -bard
				shellApi.setUserField( _events.ROCKS1_FIELD, _rockData, shellApi.island);
			}
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.shellApi.setUserField(_events.PLANET_FIELD, _events.BARREN, this.shellApi.island, true);
			
			
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			setupFallingRocks();
			
			setupDoors();
			
			setupBats();
		}	
		
		
		
		private function setupDoors():void
		{
			var d1:Entity = getEntityById("door1");
			d1.add(new Sleep(false, true));
			var door:Door = d1.get(Door);
			//door.opened = true;
			var inter:SceneInteraction = d1.get(SceneInteraction);
			inter.reached.removeAll();
			inter.reached.add(handleDoor);
			
			var d2:Entity = getEntityById("door2");
			d2.add(new Sleep(false, true));
			door = d2.get(Door);
			door.opened = true;
			inter = d2.get(SceneInteraction);
			inter.reached.removeAll();
			inter.reached.add(handleDoor);
			
			_doorSys = DoorSystem(getSystem(DoorSystem));
		}
		
		private function handleDoor(p:Entity, doorEnt:Entity):void
		{
			_doorSys.openDoor(doorEnt);
		}
		
		private function addEdge(clip:DisplayObject, offset:Number = 30):Edge
		{
			var bounds:Rectangle = clip.getBounds(clip);
			var edge:Edge = new Edge();
			edge.unscaled.top = -(bounds.height * .5 - offset);
			edge.unscaled.bottom = bounds.height * .5 - offset;
			edge.unscaled.left = -(bounds.width * .4 - offset);
			edge.unscaled.right = bounds.width * .4 - offset;
			return edge;
		}
		
		private function setupFallingRocks():void
		{
			_meteorSystem = MeteorSystem( this.addSystem(new MeteorSystem()));
			_shadowSystem = GroundShadowSystem( this.addSystem(new GroundShadowSystem()));
			
			_profile = shellApi.profileManager.active;
			_rockData = shellApi.getUserField( _events.ROCKS1_FIELD, shellApi.island ) as Array;
			if( _rockData == null )
			{
				_rockData = [0,1,2,3,4,5,6]
				shellApi.setUserField( _events.ROCKS1_FIELD, _rockData, shellApi.island );
			}
			
			var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
			
			//			var validHit:ValidHit = new ValidHit("jello");
			//			validHit.inverse = true;
			//			player.add(validHit);
			super.player.add( new Mass(0) );
			
			var sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
			var clip:MovieClip = _hitContainer["meteor"];
			var edge:Edge = addEdge(clip);
			_meteor = sceneObjectCreator.createCircle(clip,0.1,_hitContainer,clip.x,clip.y,new Motion(),new SceneObjectMotion(),null, this, null, [PlatformCollider, WallCollider, SceneCollider], 300);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				Display(_meteor.get(Display)).convertToBitmaps(PerformanceUtils.defaultBitmapQuality);
			}
			Motion(_meteor.get(Motion)).acceleration = new Point(0, MotionUtils.GRAVITY);
			Motion(_meteor.get(Motion)).maxVelocity.y = 2600;
			_meteor.add(new CurrentHit());
			_meteor.add(new Id("meteor"));
			_meteor.add(edge);
			var meteor:Meteor = new Meteor();
			meteor.state = Meteor.FALLING;
			_meteor.add(meteor);
			_meteor.add(getEntityById("meteorHaz").get(Hazard));
			// add particles
			_meteor.add(new Children());
			var meteorEmitter:GlassParticles = new GlassParticles();
			meteorEmitter.init(BitmapUtils.createBitmapData(_hitContainer["part1"]),250,-500,0,500);
			meteorEmitter.addInitializer( new Lifetime( 0.5, 2 ) );
			var meteorEmitEnt:Entity = EmitterCreator.create(this, _hitContainer, meteorEmitter, 0, 0,_meteor,null,_meteor.get(Spatial));
			this._hitContainer.setChildIndex(clip, this._hitContainer.numChildren - 1);
			audioGroup.addAudioToEntity(_meteor, "meteorHaz");
			new HitCreator().addHitSoundsToEntity(_meteor,audioGroup.audioData,shellApi,"meteorHaz");
			
			_meteor.remove(SceneObjectMotion);
			_meteor.remove(SceneObjectHit);
			_meteor.remove(PlatformReboundCollider);
			
			// shadow on ground
			clip = _hitContainer["shadow"];
			_shadow = EntityUtils.createMovingEntity(this,clip);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				Display(_shadow.get(Display)).convertToBitmaps(PerformanceUtils.defaultBitmapQuality);
			}	
			Display(_shadow.get(Display)).moveToFront();
			_shadow.add(new Id("shadow"));
			var follow:FollowTarget = new FollowTarget(_meteor.get(Spatial),1,false,false);
			follow.properties = new Vector.<String>();
			follow.properties.push("x");
			_shadow.add(follow);
			_shadow.add(new GroundShadow());
			
			meteor.impactSig = new Signal();
			meteor.impactSig.add(hideShadow);
			
			_meteor.get(Children).children.push(_shadow);
			
			// rocks
			var rock:Entity;
			var hit:Entity;
			var childs:Children;
			var rockHit:MeteorHitRock;
			// single layer rocks
			for (var i:int = 0; i <= 3; i++) 
			{
				clip = _hitContainer["rock"+i];
				// check user field
				if(_rockData.indexOf(i)!= -1){
					rock = EntityUtils.createSpatialEntity(this, clip);
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						Display(rock.get(Display)).convertToBitmaps(PerformanceUtils.defaultBitmapQuality);
					}					
					childs = new Children();
					hit = getEntityById("rockF"+i);	
					hit.remove(Sleep);
					childs.children.push(hit);
					rockHit = new MeteorHitRock();
					rock.add(rockHit);
					rockHit.onHitSignal = new Signal();
					rockHit.onHitSignal.addOnce(Command.create(rockSmashed,i));
					rock.add(childs);
					rock.add(new Id("rock"+i));
					addRockParticles(rock);
					audioGroup.addAudioToEntity(rock, "rockF0");
					new HitCreator().addHitSoundsToEntity(rock,audioGroup.audioData,shellApi,"rockF0");
				}
				else{
					_hitContainer.removeChild(clip);
					removeEntity(getEntityById("rockF"+i));
				}
			}
			
			// vertical stacked rocks, need to fall and stuff
			for (var j:int = 4; j <= 6; j++) 
			{
				clip = _hitContainer["rock"+j];
				if(_rockData.indexOf(j)!= -1){
					rock = sceneObjectCreator.createBox(clip, 0.1, _hitContainer,clip.x,clip.y,null, null,null, this, null, null, 1000,true);
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						Display(rock.get(Display)).convertToBitmaps(PerformanceUtils.defaultBitmapQuality);
					}	
					edge = addEdge(clip, -3.2);
					rock.add(edge);
					
					rock.add(new PlatformCollider());
					rock.add(new SceneCollider());
					rock.add(new Id("rock"+j));
					
					childs = new Children();
					hit = getEntityById("rockW"+j);
					Display(hit.get(Display)).isStatic = false;
					follow = new FollowTarget(rock.get(Spatial));
					hit.add(follow);
					childs.children.push(hit);
					rock.add(childs);
					rockHit = new MeteorHitRock();
					rock.add(rockHit);
					rockHit.onHitSignal = new Signal();
					rockHit.onHitSignal.addOnce(Command.create(rockSmashed,j));
					addRockParticles(rock);
					audioGroup.addAudioToEntity(rock, "rockF0");
					new HitCreator().addHitSoundsToEntity(rock,audioGroup.audioData,shellApi,"rockF0");
					//rock.add(validHit);
				}
				else{
					_hitContainer.removeChild(clip);
					removeEntity(getEntityById("rockW"+j));
				}
			}			
			
			launchMeteor();
		}
		
		private function rockSmashed(rock:Entity, ID:int):void
		{
			// remove rock from data, save to user field
			_rockData.splice(_rockData.indexOf(ID),1);
			shellApi.setUserField(_events.ROCKS1_FIELD, _rockData, shellApi.island);
		}
		
		private function addRockParticles(rock:Entity):void
		{
			var rockEmitter:GlassParticles = new GlassParticles();
			rockEmitter.init(BitmapUtils.createBitmapData(_hitContainer["part0"]),200,300,0,600);
			rockEmitter.addInitializer( new Lifetime( 0.5, 2 ) );
			EmitterCreator.create(this, _hitContainer, rockEmitter, 0, 0, rock, null, rock.get(Spatial));
		}		
		
		
		private function hideShadow(meteor:Entity):void
		{
			GroundShadow(_shadow.get(GroundShadow)).on = false;
		}
		
		private function launchMeteor():void
		{
			// target near player
			var meteor:Meteor = _meteor.get(Meteor);
			var pPos:Point = EntityUtils.getPosition(player);
			var mPos:Point = new Point();
			mPos.x = GeomUtils.randomInRange(pPos.x - targetRadius*1.5, pPos.x + targetRadius*.5);
			mPos.y = pPos.y - 800; 
			EntityUtils.position(_meteor,mPos.x, mPos.y);
			meteor.state = Meteor.FALLING;
			//meteor.fallSpeed = 300 + GeomUtils.randomInt(-60, 60);
			_meteor.get(Motion).acceleration = new Point(0, meteor.fallSpeed);
			_meteor.get(Motion).velocity.x = meteor.xDrift;
			meteor.spinRate = 30 + GeomUtils.randomInt(-90, 40);
			//meteor.xDrift = 80 + GeomUtils.randomInt(-100, 70);
			AudioUtils.playSoundFromEntity(_meteor, FALL_SOUND, 800, 0.50, 1.5, Linear.easeInOut);
		}
		
		private function setupBats():void
		{
			var bat:Entity;
			var inter:Interaction;
			for (var i:int = 0; i < 2; i++) 
			{
				bat = getEntityById("batInteraction"+i);
				inter = bat.get(Interaction);
				inter.click.add(dontTouch);
			}
			
		}
		
		private function dontTouch(...p):void
		{
			Dialog(player.get(Dialog)).sayById("nope");
		}		
		
		
		
		
		
		
		
		
		
		
		
	}
}