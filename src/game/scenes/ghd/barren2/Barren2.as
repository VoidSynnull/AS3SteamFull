package game.scenes.ghd.barren2
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
	import game.components.hit.Wall;
	import game.components.hit.Zone;
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
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	import org.flintparticles.common.initializers.Lifetime;
	import org.osflash.signals.Signal;
	
	public class Barren2 extends GalacticHotDogScene
	{
		private var _meteorSystem:MeteorSystem;
		private var _shadowSystem:GroundShadowSystem;
		private var _meteor:Entity;
		private var _shadow:Entity;
		
		private var targetRadius:Number = 200;
		private var dagger:Entity;
		private var _doorSys:DoorSystem;
		private var _profile:ProfileData;
		private var _rockData:Array;
		
		private const FALL_SOUND:String = SoundManager.EFFECTS_PATH + "object_fall_01.mp3";
		
		public function Barren2()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/barren2/";
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
			if(event == "free_dagger"){
				daggerEscapedComment(null);
				var rock:Entity = getEntityById("rock7");
				for each (var ent:Entity in rock.get(Children).children) 
				{
					ent.remove(Wall);
				}
				removeEntity(rock);
			}
			else if(event == "resetRocksPlz")
			{
				if(!_profile){
					_profile = shellApi.profileManager.active;
				}
				_rockData = [0,1,2,3,4,5,6,7];
				shellApi.setUserField(_events.ROCKS2_FIELD, _rockData, shellApi.island);
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
			
			setupDagger();
			
			setupDoors();
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
			
			_doorSys = DoorSystem(getSystem(DoorSystem));
		}
		
		private function handleDoor(p:Entity, doorEnt:Entity):void
		{
			_doorSys.openDoor(doorEnt);
		}
		
		private function addEdge(clip:DisplayObject, offest:Number = 50):Edge
		{
			var bounds:Rectangle = clip.getBounds(clip);
			var edge:Edge = new Edge();
			edge.unscaled.top = -(bounds.height * .5 - offest);
			edge.unscaled.bottom = bounds.height * .5 - offest;
			edge.unscaled.left = -(bounds.width * .4 - offest);
			edge.unscaled.right = bounds.width * .4 - offest;
			return edge;
		}
		
		private function setupDagger():void
		{
			dagger = getEntityById("dagger");
			if(!shellApi.checkEvent(_events.RECOVERED_DAGGER)){
				// dagger comments when player hits a zone
				var zoneEnt:Entity = getEntityById("daggerZone");
				var zone:Zone = zoneEnt.get(Zone);
				zone.entered.add(daggerTrappedComment);
				dagger.remove(SceneInteraction);
			}else{	
				// remove dagger 
				removeEntity(dagger);
			}
		}
		
		private function daggerTrappedComment(z:String, id:String):void
		{
			if(id=="player"){
				SceneUtil.setCameraTarget(this, dagger);
				SceneUtil.lockInput(this, true, false);
				Dialog(dagger.get(Dialog)).sayById("trapped");
				Dialog(dagger.get(Dialog)).complete.addOnce(unlock);
				Zone(getEntityById("daggerZone").get(Zone)).entered.removeAll();
			}
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function daggerEscapedComment(rock:Entity):void
		{
			// dagger comments and runs off when wall rock is broken
			if(dagger.has(Dialog)){
				SceneUtil.setCameraTarget(this, dagger);
				SceneUtil.lockInput(this, true, false);
				Dialog(dagger.get(Dialog)).sayById("escaped");
				Dialog(dagger.get(Dialog)).complete.addOnce(runOff);
			}
		}
		
		private function runOff(...p):void
		{
			SceneUtil.setCameraTarget(this, player);
			var targ:Point =  EntityUtils.getPosition(getEntityById("door1")); 
			CharUtils.moveToTarget(dagger,targ.x,targ.y,false,hideDagger);
			dagger.remove(WallCollider);
		}
		
		private function hideDagger(...p):void
		{
			removeEntity(dagger);
			shellApi.triggerEvent(_events.RECOVERED_DAGGER, true);
			SceneUtil.lockInput(this, false, false);
		}
		
		private function setupFallingRocks():void
		{
			_meteorSystem = MeteorSystem( this.addSystem(new MeteorSystem()));
			_shadowSystem = GroundShadowSystem( this.addSystem(new GroundShadowSystem()));
			
			_profile = shellApi.profileManager.active;
			_rockData = shellApi.getUserField(_events.ROCKS2_FIELD, shellApi.island) as Array;
			if(_rockData == null)
			{
				_rockData = [0,1,2,3,4,5,6,7];
				shellApi.setUserField(_events.ROCKS2_FIELD, _rockData, shellApi.island);
			}
			trace(this," :: ROCKS: "+_rockData);
			
			var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
			
			// TODO: add valid hit checking to bounce system
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
			// wall & stalagmites
			for (var i:int = 5; i <= 7; i++) 
			{
				clip = _hitContainer["rock"+i];
				if(_rockData.indexOf(i)!= -1 || (i == 7 && !shellApi.checkEvent(_events.RECOVERED_DAGGER))){
					rock = EntityUtils.createSpatialEntity(this, clip);
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						Display(rock.get(Display)).convertToBitmaps(PerformanceUtils.defaultBitmapQuality);
					}	
					rock.add(new Id("rock"+i));
					childs = new Children();
					hit = getEntityById("rockW"+i);
					hit.remove(Sleep);
					childs.children.push(hit);
					rockHit = new MeteorHitRock();
					rock.add(rockHit);
					rock.add(childs);
					addRockParticles(rock);		
					rockHit.onHitSignal = new Signal();
					rockHit.onHitSignal.addOnce(Command.create(rockSmashed,i));
					if(i == 7){
						// dagger trapping rock, fires signal
						rockHit.onHitSignal.addOnce(daggerEscapedComment);
					}
				}
				else{
					_hitContainer.removeChild(clip);
					removeEntity(getEntityById("rockW"+i));
				}
			}
			
			// vertical stacked rocks, need to fall and stuff
			for (var j:int = 0; j <= 4; j++) 
			{
				clip = _hitContainer["rock"+j];
				if(_rockData.indexOf(j)!= -1){
					rock = sceneObjectCreator.createBox(clip, 0.1, _hitContainer,clip.x,clip.y,null, null,null, this, null, null, 1000,true);
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						Display(rock.get(Display)).convertToBitmaps(PerformanceUtils.defaultBitmapQuality);
					}	
					rock.add(new PlatformCollider());
					rock.add(new SceneCollider());
					edge = addEdge(clip, 1);
					rock.add(edge);
					rock.add(new Id("rock"+j));
					childs = new Children();
					hit = getEntityById("rockW"+j);
					Display(hit.get(Display)).isStatic = false;
					follow = new FollowTarget(rock.get(Spatial));
					hit.add(follow);
					childs.children.push(hit);
					rockHit = new MeteorHitRock();
					rock.add(rockHit);
					rock.add(childs);
					addRockParticles(rock);		
					rockHit.onHitSignal = new Signal();
					rockHit.onHitSignal.addOnce(Command.create(rockSmashed,j));
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
			shellApi.setUserField(_events.ROCKS2_FIELD, _rockData, shellApi.island);
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
	}
}