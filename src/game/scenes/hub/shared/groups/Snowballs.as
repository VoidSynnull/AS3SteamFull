package game.scenes.hub.shared.groups
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.character.Npc;
	import game.components.entity.character.Player;
	import game.components.hit.Zone;
	import game.components.input.Input;
	import game.components.motion.nape.NapeMotion;
	import game.components.motion.nape.NapeSpace;
	import game.components.smartFox.SFScenePlayer;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.nape.NapeCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.poptropolis.ShotputAnim;
	import game.data.ui.ToolTipType;
	import game.scene.template.GameScene;
	import game.scene.template.NapeGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.SFSceneGroup;
	import game.scenes.arab1.shared.particles.SmokeParticles;
	import game.scenes.hub.shared.components.SnowballPlayer;
	import game.scenes.hub.shared.particles.SnowballSplat;
	import game.scenes.hub.shared.systems.SnowballPlayerSystem;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	import nape.callbacks.CbEvent;
	import nape.callbacks.CbType;
	import nape.callbacks.InteractionCallback;
	import nape.callbacks.InteractionListener;
	import nape.callbacks.InteractionType;
	import nape.geom.Vec2;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.phys.Material;
	import nape.shape.Polygon;
	
	public class Snowballs extends Group
	{
		public static var GROUP_ID:String					 = "snowballs";
		
		protected static const BUTTON_OFFSET:int = 10;
		protected static const BUTTON_BUFFER:int = 80;
		
		protected static const BALL_THROW_POWER:int = 840;
		
		public function Snowballs(groundOffset:Number = 100, inZone:Zone = null)
		{
			super();
			super.id = GROUP_ID;
			_groundOffset = groundOffset;
			_zone = inZone;
			if(_zone){
				_zone.entered.add(onZoneEntered);
				_zone.exitted.add(onZoneExitted);
			}
		}
		
		override public function added():void
		{
			var scene:GameScene = this.parent as GameScene;
			
			// physics
			scene.sceneData.bounds.height -= _groundOffset;
			setupPhysics();
			scene.sceneData.bounds.height += _groundOffset;
						
			shellApi.loadFile(shellApi.assetPrefix + "scenes/hub/shared/snowball.swf", initSnowball);
			
			this.addSystem(new SnowballPlayerSystem(), SystemPriorities.update);
		}
		
		public function enableMultiplayer():void{
			// multiplayer
			var sfSceneGroup:SFSceneGroup = this.getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			sfSceneGroup.objectRecieved.add(onMPObjectRecieved); 
		}
		
		private function initSnowball(clip:MovieClip):void
		{
			_snowballBMD = new BitmapData(clip["snowball"].width, clip["snowball"].height, true, 0x00000000);
			BitmapData(_snowballBMD.draw(clip["snowball"]));
			clip.removeChild(clip["snowball"]);
			
			var scene:GameScene = this.parent as GameScene;
			scene.overlayContainer.addChild(clip);

			_snowballButton = ButtonCreator.createButtonEntity(clip["button_snowball"], this, Command.create(pickupSnowball, scene.shellApi.player), null, null, null, false);
			if(_zone)
				Display(_snowballButton.get(Display)).visible = false; // hide it by default
			
			var spatial:Spatial = _snowballButton.get(Spatial);
			spatial.x = shellApi.viewportWidth - ( BUTTON_BUFFER/2 + BUTTON_OFFSET );
			spatial.y = BUTTON_BUFFER*2.5;
		}
		
		public function addPlayer(entity:Entity, force:Boolean = false):void
		{
			var scene:GameScene = this.parent as GameScene;
			if(scene.shellApi.player == entity)
				Display(_snowballButton.get(Display)).visible = true;
			
			if(entity.has(Player) || entity.has(SFScenePlayer) || force)
				entity.add(new SnowballPlayer(entity, _napeGroup, _playerCollisionType));
		}
		
		public function removePlayer(entity:Entity):void
		{
			var scene:GameScene = this.parent as GameScene;
			if(scene.shellApi.player == entity)
				Display(_snowballButton.get(Display)).visible = false;
			
			if(entity.has(SnowballPlayer))
				entity.remove(SnowballPlayer);
		}
		
		private function onZoneExitted(zoneID:String, entityID:String):void
		{
			var scene:GameScene = this.parent as GameScene;
			removePlayer(scene.getEntityById(entityID));
		}
		
		private function onZoneEntered(zoneID:String, entityID:String):void
		{
			var scene:GameScene = this.parent as GameScene;
			addPlayer(scene.getEntityById(entityID));
		}
		
		public function enableSnowballHit(entity:Entity):void{
			
		}
		
		private function setupPhysics():void
		{
			var scene:PlatformerGameScene = this.parent as PlatformerGameScene;
			
			_napeGroup = new NapeGroup();
			_napeGroup.setupGameScene(scene, _debug);
			
			var areaWidth:int = scene.sceneData.bounds.width;
			var areaHeight:int = scene.sceneData.bounds.height;	
			
			var spaceEntity:Entity = _napeGroup.getEntityById(NapeCreator.SPACE_ENTITY);
			_napeSpace = spaceEntity.get(NapeSpace);
			
			_groundCollisionType = new CbType();
			_projectileCollisionType = new CbType();
			_playerCollisionType = new CbType();
			
			_napeSpace.space.gravity = new Vec2(0,700);
			_napeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, _groundCollisionType, _projectileCollisionType, handleLand));
			_napeSpace.space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, _playerCollisionType, _projectileCollisionType, handleHitPlayer));
			
			_napeGroup.floor.cbTypes.add(_groundCollisionType);
			
			//_napeSpace.space.listeners.add(new PreListener(InteractionType.COLLISION, _groundCollisionType, _projectileCollisionType, projToGround, 0, true));
		}
		
		private function handleLand(collision:InteractionCallback):void{
			var body:Body = collision.int2.castBody;
			
			// render snowball inert
			destroySnowball(body);
			body.cbTypes.clear();
			
			// remove cbType
			//AudioUtils.play(this, SoundManager.EFFECTS_PATH+"ls_snow_02.mp3");
			
			// start destroy process of snowball (timed)
			
			
		}
		
		private function handleHitPlayer(collision:InteractionCallback):void{
			var playerBody:Body = collision.int1.castBody;
			var snowballBody:Body = collision.int2.castBody;
			
			var throwingEntity:Entity = snowballBody.userData.thrownByEntity as Entity;
			var hitEntity:Entity = playerBody.userData.entity as Entity;
			
			//trace(Id(throwingEntity.get(Id)).id+" scores a hit on "+Id(hitEntity.get(Id)).id);
			
			if(throwingEntity != hitEntity){
				var splat:SnowballSplat = snowballBody.userData.splat as SnowballSplat;
				splat.splat(snowballBody.velocity);
				destroySnowball(snowballBody, true);
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"small_pow_05.mp3");
				//CharUtils.setAnim(hitEntity, Hurt);
			}
		}
		
		private function onMPObjectRecieved(obj:Object, whoSentIt:Entity):void{
			if(obj.hasOwnProperty("snowballAction")){
				switch(obj.snowballAction){
					case "pickupSnowball":
						pickupSnowball(null, whoSentIt, true);
						break;
					case "readyThrow":
						readyThrow(whoSentIt, obj.faceRight);
						break;
					case "throwSnowball":
						throwSnowball(whoSentIt, new Spatial(obj.tX, obj.tY));
						break;
				}
			}
		}
		
		private function pickupSnowball(button:Entity, entity:Entity, fromMP:Boolean = false):void
		{
			var scene:GameScene = this.parent as GameScene;
			var player:Entity = scene.shellApi.player;
			var fsmControl:FSMControl = entity.get(FSMControl);
			
			if(fsmControl.state.type == "stand" || entity != player){
				
				// entity picks up snowball
				CharUtils.setAnim(entity, Place);
				
				// entity locked in place
				if(player == entity){
					CharUtils.freeze(entity);
					FSMControl(entity.get(FSMControl)).active = false;
				}
				
				// cursor turns into target
				scene.shellApi.defaultCursor = ToolTipType.TARGET;
				
				// listen for interaction anywhere in scene
				SceneUtil.getInput(scene).inputDown.addOnce(handleDown);
				
				// after a moment, put a snowball in hand
				SceneUtil.addTimedEvent(this, new TimedEvent(0.4, 1, getSnowBall));
				
				// send multiplayer signal
				if(!fromMP){
					var sfSceneGroup:SFSceneGroup = parent.getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
					sfSceneGroup.shareObject({snowballAction:"pickupSnowball"});
				}
			}
		}
		
		private function getSnowBall(...p):void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"ls_crisp_snow_01.mp3");
			
			// puts snowball in player's hand
			
		}
		
		private function handleDown(input:Input):void{
			var scene:GameScene = this.parent as GameScene;
			var player:Entity = scene.shellApi.player;
			
			var tSpatial:Spatial = new Spatial(input.target.x + scene.shellApi.camera.viewport.x, input.target.y + scene.shellApi.camera.viewport.y);
			
			readyThrow(player, tSpatial.x >= Spatial(player.get(Spatial)).x);
			
			// listen for throw label
			Timeline(CharUtils.getTimeline(player)).handleLabel("launch", Command.create(throwSnowball, player, tSpatial));
			
			var sfSceneGroup:SFSceneGroup = parent.getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
			sfSceneGroup.shareObject({snowballAction:"readyThrow", faceRight:tSpatial.x >= Spatial(player.get(Spatial)).x});
		}
		
		private function readyThrow(entity:Entity, faceRight:Boolean):void{
			
			// face entity
			CharUtils.setDirection(entity, faceRight);
			
			// play animation
			CharUtils.setAnim(entity, ShotputAnim);
			CharUtils.getTimeline( entity ).gotoAndPlay("start");
		}
		
		private function throwSnowball(entity:Entity, tSpatial:Spatial):void
		{
			
			var scene:GameScene = this.parent as GameScene;
			var player:Entity = scene.shellApi.player;

			var snowball:Entity = makeSnowball(entity);
			var snowballSpatial:Spatial = snowball.get(Spatial);
			
			var pSpatial:Spatial = entity.get(Spatial);;
			var angle:Number = Math.atan2( tSpatial.y - pSpatial.y, tSpatial.x - pSpatial.x ); 
			var vX:Number = Math.cos(angle)*BALL_THROW_POWER;
			var vY:Number = Math.sin(angle)*BALL_THROW_POWER;
			
			var body:Body;
			
			body = snowball.get(NapeMotion).body;
			
			// give it a cbType to listen for collisions
			body.cbTypes.add(_projectileCollisionType);
			body.userData.entity = snowball;
			
			if(entity == player){ // from player
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"whoosh_09.mp3");
			
				snowballSpatial.x = Spatial(player.get(Spatial)).x;
				snowballSpatial.y = Spatial(player.get(Spatial)).y;

				var sfSceneGroup:SFSceneGroup = parent.getGroupById(SFSceneGroup.GROUP_ID) as SFSceneGroup;
				sfSceneGroup.shareObject({snowballAction:"throwSnowball", tX:tSpatial.x, tY:tSpatial.y});
				
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, resetPlayer));
				
			} else { // from other player
				snowballSpatial.x = Spatial(entity.get(Spatial)).x;
				snowballSpatial.y = Spatial(entity.get(Spatial)).y;
			}
			
			body.velocity = new Vec2(vX,vY);
		}
		
		private function resetPlayer():void
		{
			var scene:GameScene = this.parent as GameScene;
			var player:Entity = scene.shellApi.player;
			
			scene.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			
			CharUtils.setAnim(player, Stand);
			CharUtils.freeze(player, false);
			
			FSMControl(player.get(FSMControl)).active = true;
		}
		
		private function makeSnowball(thrownBy:Entity):Entity
		{
			var bitmap:Bitmap = new Bitmap(_snowballBMD);
			bitmap.x -= bitmap.width / 2;
			bitmap.y -= bitmap.height / 2;
			var sprite:Sprite = new Sprite();
			sprite.addChild(bitmap);
			var scene:PlatformerGameScene = this.parent as PlatformerGameScene;
			var player:Entity = scene.shellApi.player;
			var pSpatial:Spatial = player.get(Spatial);
			
			var snowBallShape:Polygon = new Polygon(Polygon.regular(bitmap.width/2,bitmap.height/2,5));
			snowBallShape.material = Material.sand();
			
			var ball:Body = new Body(BodyType.DYNAMIC);
			ball.shapes.add(snowBallShape);
			ball.cbTypes.add(_projectileCollisionType);
			ball.userData.thrownByEntity = thrownBy;
			
			var snowball:Entity = _napeGroup.creator.createNapeObject(pSpatial.x, pSpatial.y - 40, _napeSpace.space, ball, "ball");
			snowball.add(new Display(sprite, scene.hitContainer));
			snowball.add(new Id("p"+_p));
			
			// particles
			var snowballSplat:SnowballSplat = new SnowballSplat();
			var splatEmitter:Entity = EmitterCreator.create(this, scene.hitContainer, snowballSplat, 0, -20, null, null, snowball.get(Spatial));
			snowballSplat.init(this, splatEmitter);

			ball.userData.splat = snowballSplat;
			
			_napeGroup.addEntity(snowball);
			
			_p++;
			
			return snowball;
		}
		
		private function destroySnowball(body:Body, instant:Boolean = false):void{
			if(!body.userData.destroying){
				if(!instant){
					body.userData.destroying = true;
					// destroy snowball after 5 seconds
					SceneUtil.addTimedEvent(this, new TimedEvent(5, 1, Command.create(destroyBody, body)));
				} else {
					destroyBody(body);
				}
			}
		}
		
		private function destroyBody(body:Body):void{
			body.userData.thrownBy = null;
			body.userData.splat = null;
			body.cbTypes.clear();
			body.space = null;
			this.removeEntity(body.userData.entity);
		}
		
		
		public function get snowballButton():Entity{ return _snowballButton }
		public function get napeSpace():NapeSpace{ return _napeSpace }
		public function get groundCollisionType():CbType{ return _groundCollisionType }
		
		private var _snowballButton:Entity;
		private var _snowballBMD:BitmapData;
		private var _napeGroup:NapeGroup;
		private var _napeSpace:NapeSpace;
		private var _groundCollisionType:CbType;
		private var _projectileCollisionType:CbType;
		private var _playerCollisionType:CbType;
		private var _p:int;
		
		private var _zone:Zone;
		
		private var _debug:Boolean;
		private var _groundOffset:Number;
	}
}