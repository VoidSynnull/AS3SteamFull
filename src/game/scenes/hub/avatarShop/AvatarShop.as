package game.scenes.hub.avatarShop
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Think;
	import game.data.character.PartDefaults;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.hub.HubEvents;
	import game.systems.motion.ProximitySystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.Utils;
	
	public class AvatarShop extends PlatformerGameScene
	{
		private var _characterGroup:CharacterGroup;
		private var _partDefaults:PartDefaults = new PartDefaults();
		private var _tween:Tween;
		
		private var _lever:Entity;
		private var _curtain:Entity;
		
		private var _pullLeft:Boolean = false;
		
		public function AvatarShop()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/hub/avatarShop/";
			
			super.init(container);
		}
		
		override public function destroy():void
		{
			this.shellApi.eventTriggered.remove(this.eventTriggered);
			super.destroy();
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
			
			this.shellApi.eventTriggered.add(this.eventTriggered);
			
			this._tween = this.getGroupEntityComponent(Tween);
			
			this.createBitmap(this._hitContainer["brickPillarRight"]);
			this.createBitmap(this._hitContainer["brickExit"]);
			this.createBitmapSprite(this._hitContainer["curtain"]);
			
			this.setupTailor();
			this.setupColorizer();
			this.setupMannequins();
			this.setupLever();
			this.setupCurtain();
			this.setupBarberPole();
		}
		
		private function setupTailor():void
		{
			this.addSystem(new ProximitySystem());
			
			var tailor:Entity = this.getEntityById("tailor");
			var proximity:Proximity = new Proximity(400, this.player.get(Spatial));
			proximity.entered.addOnce(this.playerNearTailor);
			tailor.add(proximity);
		}
		
		private function playerNearTailor(entity:Entity):void
		{
			this.removeSystemByClass(ProximitySystem);
			entity.remove(Proximity);
			
			var dialogId:String = "hello_again";
			if(!this.shellApi.checkEvent(HubEvents(this.events).TALKED_TO_TAILOR))
			{
				this.shellApi.completeEvent(HubEvents(this.events).TALKED_TO_TAILOR);
				dialogId = "new_outfit";
			}
			
			var dialog:Dialog = entity.get(Dialog);
			dialog.sayById(dialogId);
		}
		
		private function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var barber:Entity = this.getEntityById("barber");
			var tailor:Entity = this.getEntityById("tailor");
			
			if(event == "tell_joke")
			{
				Dialog(barber.get(Dialog)).sayById("bad_joke_" + Utils.randInRange(1, 4));
			}
			else if(event == "laugh")
			{
				CharUtils.setAnim(barber, Laugh);
			}
			else if(event == "point_to_colorizer")
			{
				CharUtils.setDirection(barber, false);
				CharUtils.setAnim(barber, PointItem);
			}
			else if(event == "cant_recognize")
			{
				Dialog(barber.get(Dialog)).sayById("recognize");
			}
			else if(event == "proud")
			{
				CharUtils.setAnim(tailor, Proud);
			}
			else if(event == "think")
			{
				CharUtils.setAnim(tailor, Think, false, 60);
			}
		}
		
		private function setupColorizer():void
		{
			var entity:Entity = this.getEntityById("colorizerInteraction");
			var sceneInteraction:SceneInteraction = entity.get(SceneInteraction);
			sceneInteraction.reached.add(this.onColorizerReached);
		}
		
		private function onColorizerReached(player:Entity, entity:Entity):void
		{
			this.addChildGroup(new Colorizer(this.overlayContainer));
		}
		
		private function setupMannequins():void
		{
			this._characterGroup = this.getGroupById("characterGroup") as CharacterGroup;
			var gender:String = this.shellApi.profileManager.active.gender;
			
			for(var index:int = 1; index <= 3; ++index)
			{
				var mannequin:Entity = this.getEntityById("mannequin" + index);
				this._characterGroup.configureCostumizerMannequin(mannequin);
				
				var curtain:DisplayObject = this._hitContainer["curtain"];
				var childIndex:int = curtain.parent.getChildIndex(curtain);
				
				var display:DisplayObject = mannequin.get(Display).displayObject;
				display.parent.setChildIndex(display, childIndex);
				
				SkinUtils.setRandomSkin(mannequin, this._partDefaults, gender);
			}
		}
		
		private function setupLever():void
		{
			this._lever = this.getEntityById("leverInteraction");
			
			var sceneInteraction:SceneInteraction 	= this._lever.get(SceneInteraction);
			sceneInteraction.minTargetDelta.x 		= 20;
			sceneInteraction.reached.add(this.pullLever);
			
			var display:Display = this._lever.get(Display);
			display.isStatic 	= false;
			DisplayUtils.moveToTop(display.displayObject);
		}
		
		private function pullLever(player:Entity, lever:Entity):void
		{
			SceneUtil.lockInput(this, true);
			CharUtils.setAnim(this.player, Pull);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_04a.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			var spatial:Spatial = this.player.get(Spatial);
			
			if(spatial.x < 960)
			{
				this._tween.to(this.player.get(Spatial), 0.5, {x:930, onComplete:this.onLeverComplete});
				this._tween.to(this._lever.get(Spatial), 0.5, {rotation:-45});
			}
			else
			{
				this._tween.to(this.player.get(Spatial), 0.5, {x:990, onComplete:this.onLeverComplete});
				this._tween.to(this._lever.get(Spatial), 0.5, {rotation:45});
			}
			
			spatial.x = 960;
		}
		
		private function onLeverComplete():void
		{
			this._tween.to(this._lever.get(Spatial), 0.5, {rotation:0});
			this._tween.to(this._curtain.get(Spatial), 1, {y:225, onComplete:this.onCurtainComplete});
			
			CharUtils.stateDrivenOn(this.player);
			SceneUtil.lockInput(this, true);
		}
		
		private function onCurtainComplete():void
		{
			this._tween.to(this._curtain.get(Spatial), 1.5, {y:-35});
			
			var gender:String = this.shellApi.profileManager.active.gender;
			
			for(var index:int = 1; index <= 3; ++index)
			{
				var mannequin:Entity = this.getEntityById("mannequin" + index);
				SkinUtils.setRandomSkin(mannequin, this._partDefaults, gender);
			}
			
			CharUtils.stateDrivenOn(this.player);
			SceneUtil.lockInput(this, false);
			
			const random:int = Utils.randInRange(1, 4);
			Dialog(this.getEntityById("tailor").get(Dialog)).sayById("curtain" + random);
		}
		
		private function setupCurtain():void
		{
			this._curtain = EntityUtils.createSpatialEntity(this, this._hitContainer["curtain"]);
		}
		
		private function setupBarberPole():void
		{
			var entity:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["barberPole"]);
			BitmapTimelineCreator.convertToBitmapTimeline(entity);
			
			entity.get(Timeline).play();
		}
	}
}