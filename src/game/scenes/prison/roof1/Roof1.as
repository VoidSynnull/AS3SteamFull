package game.scenes.prison.roof1
{
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Hide;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.WalkNinja;
	import game.scene.template.AudioGroup;
	import game.scenes.prison.PrisonScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.DetectionSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.ScreenEffects;
	
	public class Roof1 extends PrisonScene
	{
		public function Roof1()
		{
			super();
			this.mergeFiles = true;
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/prison/roof1/";
			
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
			super.loaded();
			setupPushBox();
			setupLights();
			setupGuard();
			setupHideZones(4);
		}
		
		private function setupPushBox():void
		{
			var sceneObjectCreator:SceneObjectCreator = new SceneObjectCreator();
			this.addSystem(new SceneObjectHitRectSystem());
			
			player.add(new ValidHit("concrete", "baseGround", "wall"));
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			var clip:MovieClip = _hitContainer["boxBounds"];
			var bounds:Rectangle = new Rectangle(clip.x, clip.y, clip.width, clip.height);
			_hitContainer.removeChild(clip);
			clip = _hitContainer["pushBox"];
			var box:Entity = sceneObjectCreator.createBox(clip,0,super.hitContainer,clip.x,clip.y,null,null,bounds,this,null,null,400);
			box.add(new PlatformCollider());
			box.add(new ValidHit("concrete"));	
			
			var audioGroup:AudioGroup = AudioGroup(getGroupById(AudioGroup.GROUP_ID));
			audioGroup.addAudioToEntity(box, "box");
			new HitCreator().addHitSoundsToEntity(box, audioGroup.audioData, shellApi, "box");
		}
		
		private function setupLights():void
		{
			setupRoofLight("light1", 44, 5, 1315, 102);
			setupRoofLight("light2", 32, 5, 900, 100);
			
			player.add(new Hide());
			this.addSystem(new WaveMotionSystem());
			this.addSystem(new DetectionSystem(), SystemPriorities.resolveCollisions);	
		}
		
		private function setupGuard():void
		{
			// Setup the actual guard
			var building:Bitmap = this.createBitmap(_hitContainer["midbuilding"]);	
			_guard = getEntityById("guard");	
			var displayObj:DisplayObject = EntityUtils.getDisplayObject(_guard);
			DisplayUtils.moveToBack(displayObj);
			EntityUtils.removeInteraction(_guard);
			
			var black:ColorTransform = new ColorTransform(1,1,1,0,0,0);
			black.color = 0x0F1121;
			displayObj.transform.colorTransform = black;			
			
			var lightEntity:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["flashlight"]);
			_lightFollow = new FollowTarget(_guard.get(Spatial));
			_lightFollow.offset = new Point(0, -40);
			lightEntity.add(_lightFollow);
						
			CharUtils.setAnim(_guard, Walk);
			var righAnim:RigAnimation = CharUtils.getRigAnim(_guard, 1);
			if(righAnim == null)
			{
				var animSlot:Entity = AnimationSlotCreator.create(_guard);
				righAnim = animSlot.get(RigAnimation) as RigAnimation;
			}
			
			righAnim.next = WalkNinja;
			righAnim.addParts(CharUtils.HAND_BACK, CharUtils.ARM_BACK);			
			switchGuardDirection();
			
			// setup the zones
			for(var i:uint = 1; i <= 4; i++)
			{
				var zone:Zone = getEntityById("guardZone" + i).get(Zone);
				zone.entered.add(enteredGuardZone);
				zone.exitted.add(exittedGuardZone);
			}
		}
		
		private function switchGuardDirection(...args):void
		{
			var spatial:Spatial = _guard.get(Spatial);
			var endX:Number = spatial.x > 3500 ? 2640 : 3660;
			_lightFollow.offset.x = spatial.x > 3500 ? -70 : 70;
			
			CharUtils.moveToTarget(_guard, endX, 950, true, switchGuardDirection, new Point(20, 40));
			_guard.get(CharacterMotionControl).maxVelocityX = 120;
		}
		
		private function enteredGuardZone(zoneId:String, charId:String):void
		{
			if(charId == "player")
			{
				_currentPlayerZone = zoneId;
			}
			else if(charId == "guard")
			{
				_currentGuardZone = zoneId;
			}
			
			if(_currentGuardZone && _currentPlayerZone && _currentGuardZone == _currentPlayerZone)
			{
				roofCaught();
			}
		}
		
		private function exittedGuardZone(zoneId:String, charId:String):void
		{
			if(charId == "player")
			{
				_currentPlayerZone = null;
			}
			else if(charId == "guard")
			{
				_currentGuardZone = null;
			}
		}
		
		override protected function roofCaught(...args):void
		{
			_guard.get(Destination).interrupt = true;
			_currentPlayerZone = null;
			_currentGuardZone = null;
			
			var playerSpatial:Spatial = player.get(Spatial);
			roofCheckPoint = playerSpatial.x < 2300 ? new Point(170, 650) : roofCheckPoint = new Point(2500, 950);		 

			super.roofCaught();
		}
		
		override protected function sendPlayerBack(screenEffects:ScreenEffects = null):void
		{
			_guard.get(Destination).interrupt = false;
			switchGuardDirection();
			
			super.sendPlayerBack(screenEffects);
		}		
		
		private var _guard:Entity;
		private var _lightFollow:FollowTarget;
		private var _currentPlayerZone:String = null;
		private var _currentGuardZone:String = null;
	}
}