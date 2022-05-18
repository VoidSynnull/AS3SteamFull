package game.scenes.arab3.atrium
{
	import com.greensock.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.render.Reflection;
	import game.components.render.Reflective;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.PointItem;
	import game.data.sound.SoundModifier;
	import game.scenes.arab3.Arab3Events;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.atriumGame.AtriumGame;
	import game.systems.SystemPriorities;
	import game.systems.render.ReflectionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class Atrium extends Arab3Scene
	{
		private var _lampRoomDoor:Door;
		
		public function Atrium()
		{
			super();
		}
		
		override protected function addBaseSystems():void 
		{
			addSystem( new ReflectionSystem(), SystemPriorities.postRender );
			super.addBaseSystems();
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.groupPrefix = "scenes/arab3/atrium/";
			super.init( container );
		}
		
		override public function smokeReady():void
		{
			super.smokeReady();
			
			this.setupGenie();
			this.setupReflection();
			this.setupFloorWater();
			this.setupLampRoom();
			this.setupPortraits();
		}
		
		private function setupPortraits():void
		{
			for(var index:int = 1; index <= 5; ++index)
			{
				var portrait:Entity = this.getEntityById("portrait" + index + "Interaction");
				var sceneInteraction:SceneInteraction = portrait.get(SceneInteraction);
				sceneInteraction.approach = false;
				sceneInteraction.triggered.add(this.onPortraitClicked);
				
				//This is ridiculous. The portraits are being auto-made with their tooltips at the bottom.(?)
				//Have to remove and re-add them to make it work.
				ToolTipCreator.removeFromEntity(portrait);
				ToolTipCreator.addToEntity(portrait);
			}
		}
		
		private function onPortraitClicked(player:Entity, portrait:Entity):void
		{
			var id:String = Id(portrait.get(Id)).id;
			id = id.replace("Interaction", "");
			Dialog(player.get(Dialog)).sayById(id);
		}
		
		private function setupLampRoom():void
		{
			var lampRoomDoor:Entity = TimelineUtils.convertClip(this._hitContainer["lampRoomDoor"], this, null, null, false);
			
			if(!this.shellApi.checkEvent(Arab3Events(this.events).LAMP_ROOM_UNLOCKED))
			{
				var entity:Entity = this.getEntityById("doorLamp");
				this._lampRoomDoor = entity.remove(Door) as Door;
				
				var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
				sceneInteraction.reached.add(this.sayKeyDialog);
			}
			else
			{
				Timeline(lampRoomDoor.get(Timeline)).gotoAndStop("closed");
			}
		}
		
		private function sayKeyDialog(player:Entity, door:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "lock_jiggle_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			Dialog(this.player.get(Dialog)).sayById("key");
		}
		
		private function setupFloorWater():void
		{
			this.createBitmap(this._hitContainer["floorTint"]);
		}
		
		override protected function eventTriggered(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == "genie_run")
			{
				var genie:Entity = this.getEntityById("genie");
				CharUtils.setDirection(genie, true);
				
				var tween:Tween = this.getGroupEntityComponent(Tween);
				tween.to(genie.get(Spatial), 1.2, {x:1400, ease:Linear.easeIn, onComplete:playerChaseGenie});
			}
			else if(event == "use_skeleton_key")
			{
				var spatial:Spatial = this.player.get(Spatial);
				
				if(!this.shellApi.checkEvent(Arab3Events(this.events).LAMP_ROOM_UNLOCKED) && Utils.distance(spatial.x, spatial.y, 207, 520) < 200)
				{
					CharUtils.moveToTarget(this.player, 300, 520, true, onLampDoorReached, new Point(10, 100)); 
				}
			}
		}
		
		private function onLampDoorReached(...args):void
		{
			CharUtils.setDirection(this.player, false);
			CharUtils.setAnim(this.player, PointItem);
			
			this.shellApi.completeEvent(Arab3Events(this.events).LAMP_ROOM_UNLOCKED);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "door_heavy_wood_open_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			Timeline(this.getEntityById("lampRoomDoor").get(Timeline)).play();
			
			var entity:Entity = this.getEntityById("doorLamp");
			entity.add(this._lampRoomDoor);
			
			var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
			sceneInteraction.reached.remove(this.sayKeyDialog);
		}
		
		private function playerChaseGenie():void
		{
			var spatial:Spatial = this.player.get(Spatial);
			CharUtils.moveToTarget(this.player, 1400, 1240, true, playerNearHidingSpots);
		}
		
		private function playerNearHidingSpots(player:Entity):void
		{
			this.shellApi.loadScene(AtriumGame);
		}
		
		private function setupGenie():void
		{
			var genie:Entity = this.getEntityById("genie");
			this.addGenieWaveMotion(genie);
			_smokePuffGroup.addJinnTailSmoke( genie );
			
			var arab3Events:Arab3Events = Arab3Events(this.events);
			if(this.shellApi.checkEvent(arab3Events.GENIE_IN_ATRIUM) && !this.shellApi.checkEvent(arab3Events.SPOT_THE_DIFFERENCE_COMPLETE))
			{
				SceneUtil.lockInput(this, true);
				SceneUtil.setCameraPoint(this, 715, 1080);
				
				Spatial(this.player.get(Spatial)).x = 590;
				CharUtils.setDirection(this.player, true);
				
				Dialog(this.player.get(Dialog)).sayById("hide");
			}
			else if(this.shellApi.checkEvent(arab3Events.SPOT_THE_DIFFERENCE_COMPLETE) && !this.shellApi.checkEvent(arab3Events.GENIE_IN_LAMP_ROOM))
			{
				SceneUtil.lockInput(this, true);
				SceneUtil.setCameraTarget(this, genie);
				
				CharUtils.setDirection(this.player, false);
				CharUtils.setDirection(genie, false);
				
				var tween:Tween = this.getGroupEntityComponent(Tween);
				tween.to(genie.get(Spatial), 2, {x:207, y:400, ease:Linear.easeInOut, onComplete:panBackToPlayer});
			}
			else
			{
				this.removeEntity(genie);
			}
		}
		
		private function panBackToPlayer():void
		{
			this.shellApi.completeEvent(Arab3Events(this.events).GENIE_IN_LAMP_ROOM);
				
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, this.player);
			
			this.removeEntity(this.getEntityById("genie"));
			
			Dialog(this.player.get(Dialog)).sayById("lamp");
		}
		
		private function setupReflection():void
		{
			// ADD REFLECTIVE TYPES TO PLAYER
			var typesArray:Array = [ "mirror" ];
			player.add(new Reflection(typesArray));
			
			var waterIndex:int = this._hitContainer.getChildIndex(this._hitContainer.getChildByName("floorTint"));
			
			// MAKE REFLECTIVE POOL
			var clip:MovieClip = _hitContainer[ "reflection" ];
			
			var bitmap:Bitmap = new Bitmap( new BitmapData( clip.width, clip.height, true, 0x00000000 ) );
			this._hitContainer.addChildAt( bitmap, waterIndex );
			
			var entity:Entity = new Entity();
			var spatial:Spatial = new Spatial();
			spatial.x = clip.x;
			spatial.y = clip.y;
			entity.add( spatial );
			
			entity.add( new Display( bitmap )).add( new Reflective( Reflective.SURFACE_DOWN, "mirror", 0, 0));
			
			super.addEntity( entity );
		}
	}
}