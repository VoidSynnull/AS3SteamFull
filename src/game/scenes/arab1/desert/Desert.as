package game.scenes.arab1.desert
{
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.MotionTarget;
	import game.components.motion.Proximity;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Throw;
	import game.data.comm.PopResponse;
	import game.scene.template.ItemGroup;
	import game.scenes.arab1.Arab1Events;
	import game.scenes.arab1.desert.components.Awning;
	import game.scenes.arab1.desert.particles.SandFall;
	import game.scenes.arab1.desert.particles.SandStorm;
	import game.scenes.arab1.desert.particles.WaterChurn;
	import game.scenes.arab1.desert.systems.AwningSystem;
	import game.scenes.arab1.shared.Arab1Scene;
	import game.scenes.arab1.shared.creators.CamelCreator;
	import game.scenes.custom.AdMiniBillboard;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.hud.Hud;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Desert extends Arab1Scene
	{
		public function Desert()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab1/desert/";
			
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
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(535, 1125),"minibillboard/minibillboardSmallLegs.swf");	

			_events = new Arab1Events();
			//super.shellApi.eventTriggered.add(handleEventTriggered);
			
			setupParticles();
			setupAwning();
			setupDias();
			setupZones();
			setupFlags();
			setupEntrance();
			
			if(!shellApi.checkEvent(_events.CAMEL_TAKEN)){
				setupPuddle();
			}
			
			if(shellApi.checkEvent(_events.SMOKE_BOMB_LEFT) && !shellApi.checkHasItem(_events.SMOKE_BOMB)){
				setupSmokeBomb();
			} else {
				_hitContainer["smokeBomb"].visible = false;
			}
			
			setupCamel();
		}
		
		private function setupPuddle():void
		{
			_puddle = ButtonCreator.createButtonEntity(_hitContainer["puddleButton"], this, onPuddle, _hitContainer);
		}
		
		private function onPuddle(...p):void{
			Dialog(player.get(Dialog)).say("More of a puddle than a pool.");
		}
		
		private function setupSmokeBomb():void
		{
			this.addSystem(new ItemHitSystem(), SystemPriorities.checkCollisions);
			var itemHitSystem:ItemHitSystem = super.getSystem(ItemHitSystem) as ItemHitSystem;
			itemHitSystem.gotItem.removeAll();
			itemHitSystem.gotItem.add(pickupBomb);
			
			var display:Display;
			var sceneCreator:SceneItemCreator = new SceneItemCreator();
			
			_bomb = new Entity();
			_bomb.add(new Spatial());
			_bomb.add(new Sleep());
			display = new Display(_hitContainer["smokeBomb"]);
			display.isStatic = true;
			_bomb.add(display);
			_bomb.add(new Id("smokeBomb"));
			super.addEntity(_bomb);
			sceneCreator.make(_bomb, new Point(25, 100));
			
			
			/*
			_bomb = EntityUtils.createSpatialEntity(this, _hitContainer["smokeBomb"], _hitContainer);
			var sceneItemCreator:SceneItemCreator = new SceneItemCreator();
			sceneItemCreator.make(_bomb);
			
			var sceneInteraction:SceneInteraction = _bomb.get(SceneInteraction);
			
			sceneInteraction.reached.addOnce(pickupBomb);*/
		}
		
		private function pickupBomb(...p):void{
			shellApi.getItem(_events.SMOKE_BOMB, null, true);
		}
		
		private function setupCamel():void
		{
			if(shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				camelCreator.create(new Point(1550, 1440), null, 300, camelCreated);
			}
			else
				camelCreator.camelCreated.add(camelCreated);
		}
		
		private function camelCreated($entity:Entity):void{
			_camel = $entity;
			
			// if entering scene with player
			if(shellApi.checkEvent(_events.CAMEL_ON_DIAS))
			{	// raise camel up to dias
				moveCamelOnToDias();
			}
			else
			{
				var threshold:Threshold = new Threshold("x", ">=");
				threshold.threshold = 1450;
				threshold.entered.addOnce(this.placeCamelOnDias);
				_camel.add(threshold);
				this.addSystem(new ThresholdSystem());
			}
		}
		
		private function placeCamelOnDias():void
		{
			_camel.remove(Threshold);
			this.letGoCamel();
			shellApi.triggerEvent(_events.CAMEL_ON_DIAS, true);
		}
		
		private function moveCamelOnToDias():void
		{
			var edge:Edge = _camel.get(Edge);
			edge.unscaled.bottom += 45;
			
			var spatial:Spatial = _camel.get(Spatial);
			spatial.x = 1550;
			
			var motionTarget:MotionTarget = _camel.get(MotionTarget);
			motionTarget.targetX = spatial.x;
			motionTarget.targetY = 1378;
			
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(_camel), EntityUtils.getDisplayObject(player), false);
			
			// take back item on Dias (if any)
			if(_placedItem){
				Timeline(_dias.get(Timeline)).gotoAndStop("clear");
				if(_placedItem != "salt"){
					shellApi.getItem(_placedItem);
				}
				shellApi.removeEvent(_placedItem+"_on_dias"); // clear event
				_placedItem = null;
			}
		}
		
		private function takeCamel():void{
			camelCreator.setCamelsHandler(_camel, this.player);
		}
		
		private function letGoCamel():void{
			camelCreator.setCamelsHandler(_camel, null);
			moveCamelOnToDias();
		}
		
		private function setupFlags():void
		{
			BitmapUtils.convertContainer(_hitContainer["flag1"], PerformanceUtils.defaultBitmapQuality);
			BitmapUtils.convertContainer(_hitContainer["flag2"], PerformanceUtils.defaultBitmapQuality);
			
			_flag1 = TimelineUtils.convertClip(_hitContainer["flag1"], this);
			_flag2 = TimelineUtils.convertClip(_hitContainer["flag2"], this);
		}
		
		private function setupZones():void
		{
			var entity:Entity;
			var zone:Zone;
			
			if(shellApi.checkEvent(_events.CLOTH_ON_DIAS) || shellApi.checkEvent(_events.SALT_ON_DIAS) || shellApi.checkEvent(_events.GRAIN_ON_DIAS)){
				// setup stolenZone
				entity = super.getEntityById("zoneStolen");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(handleZoneEntered);
			}
			
			if(shellApi.checkEvent(_events.CAMEL_TAKEN)){
				entity = super.getEntityById("zoneOpen");
				zone = entity.get(Zone);
				zone.pointHit = true;
				zone.entered.add(finalSequence);
			}
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void{
			// have item disappear in a puff of smoke
			//_smokeBombGroup.thiefAt(_dias.get(Spatial));
			//Timeline(_dias.get(Timeline)).gotoAndStop("clear");
			
			// approach dias and then enquire
			var dSpatial:Spatial = _dias.get(Spatial);
			CharUtils.moveToTarget(player, dSpatial.x, dSpatial.y, false, null, new Point(100,100));
			Dialog(player.get(Dialog)).sayById("whereGo");
			
			// null zone
			var entity:Entity = super.getEntityById("zoneStolen");
			entity.remove(Zone);
			
			// remove event
			shellApi.removeEvent(_placedItem+"_on_dias");
			_placedItem = null;
		}
		
		override protected function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void{
			switch(event){
				case _events.CLOTH : 
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						takeItemToDias(event);
					} else {
						useCloth();
					}
					break;
				case _events.SALT :
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						takeItemToDias(event);
					} else {
						useSalt();
					}
					break;
				case _events.GRAIN :
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						takeItemToDias(event);
					} else {
						useGrain();
					}
					break;
				case _events.CAMEL_HARNESS:
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						Dialog(player.get(Dialog)).say("This item is too valuable to lose.");
					} else {
						useCamelHarnes();
					}
					break;
				case _events.LAMP:
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						Dialog(player.get(Dialog)).say("This item is too valuable to lose.");
					} else {
						useLamp();
					}
					break;
				case _events.SPY_GLASS:
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						Dialog(player.get(Dialog)).say("This item is too valuable to lose.");
					} else {
						useSpyGlass();
					}
					break;
				case _events.CROWN_JEWEL:
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						Dialog(player.get(Dialog)).say("This item is too valuable to lose.");
					} else {
						useCrownJewel();
					}
					break;
				case _events.PEARL:
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						Dialog(player.get(Dialog)).say("This item is too valuable to lose.");
					} else {
						usePearl();
					}
					break;
				case _events.IVORY_CAMEL:
					if(EntityUtils.distanceBetween(player, _dias) < 500){
						Dialog(player.get(Dialog)).say("This item is too valuable to lose.");
					} else {
						useIvoryCamel();
					}
					break;
			}
		}
		
		private function setupDias():void
		{
			_dias = ButtonCreator.createButtonEntity(_hitContainer["dias"], this, gotoDias);
			ToolTipCreator.addToEntity(_dias);
			TimelineUtils.convertClip(_hitContainer["dias"], this, _dias);
			
			// check if items are left there (to be stolen when you approach dias)
			switch(true){
				case shellApi.checkEvent(_events.GRAIN_ON_DIAS) :
					//Timeline(_dias.get(Timeline)).gotoAndStop(_events.GRAIN);
					_placedItem = _events.GRAIN;
					break;
				case shellApi.checkEvent(_events.SALT_ON_DIAS) :
					//Timeline(_dias.get(Timeline)).gotoAndStop(_events.SALT);
					_placedItem = _events.SALT;
					break;
				case shellApi.checkEvent(_events.CLOTH_ON_DIAS) :
					//Timeline(_dias.get(Timeline)).gotoAndStop(_events.CLOTH);
					_placedItem = _events.CLOTH;
					break;
			}
		}
		
		private function gotoDias(...p):void{
			var dSpatial:Spatial = _dias.get(Spatial);
			if(EntityUtils.distanceBetween(player, _dias) > 100){
				CharUtils.moveToTarget(player, dSpatial.x, dSpatial.y, false, useDias, new Point(100,100));
			} else {
				useDias();
			}
		}
		
		private function useDias(...p):void{
			if(!shellApi.checkEvent(arab.PLAYER_HOLDING_CAMEL) && !shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				if(!_placedItem){
					// open inventory
					(super.getGroupById( Hud.GROUP_ID ) as Hud).openInventory();
				} else {
					// take back item
					Timeline(_dias.get(Timeline)).gotoAndStop("clear");
					if(_placedItem != "salt"){
						shellApi.getItem(_placedItem);
					}
					shellApi.removeEvent(_placedItem+"_on_dias"); // clear event
					_placedItem = null;
				}
			} else if(shellApi.checkEvent(arab.PLAYER_HOLDING_CAMEL) && !shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
				// place camel on dias
				this.placeCamelOnDias();
			} else {
				Dialog(player.get(Dialog)).sayById("notMoving");
			}
		}
		
		public function takeItemToDias($item:String):void{
			var dSpatial:Spatial = _dias.get(Spatial);
			
			if(EntityUtils.distanceBetween(player, _dias) > 100 && EntityUtils.distanceBetween(player, _dias) < 500){
				CharUtils.moveToTarget(player, dSpatial.x, dSpatial.y, false, placeItem, new Point(100,100));
			} else if(EntityUtils.distanceBetween(player, _dias) < 100){
				placeItem();
			}
			
			function placeItem():void{
				
				if(!shellApi.checkEvent(_events.CAMEL_ON_DIAS)){
					CharUtils.setAnim(player, Throw);
					
					Timeline(_dias.get(Timeline)).gotoAndStop($item);
					
					if($item != "salt"){
						shellApi.removeItem($item);
					}
					
					// pick up item that is there
					if(_placedItem){
						shellApi.getItem(_placedItem);
						shellApi.removeEvent(_placedItem+"_on_dias"); // clear event
					}
					
					_placedItem = $item;
					
					shellApi.triggerEvent(_placedItem+"_on_dias", true); // save event
					
					merchantWarn();
				} else {
					Dialog(player.get(Dialog)).sayById("notMoving");
				}
				
			}
		}
		
		private function merchantWarn():void{
			var chance:Number = Math.random();
			var merchantDialog:Dialog;
			
			if(chance > 0.7){
				merchantDialog = Dialog(this.getEntityById("brokeMerchant").get(Dialog));
				CharUtils.setDirection(this.getEntityById("brokeMerchant"), true);
			}
			
			switch(true){
				case chance > 0.7 && chance <= 0.85 :
					merchantDialog.sayById("warn1");
					break;
				case chance > 0.85 && chance <= 1 :
					merchantDialog.sayById("warn2");
					break;
			}
		}
		
		private function setupAwning():void
		{
			this.getEntityById("awning").add(new Awning());
			this.addSystem(new AwningSystem(this, _sandParticles), SystemPriorities.checkCollisions);
		}
		
		private function setupParticles():void
		{
			_sandParticles = new SandFall();
			_sandEmitter = EmitterCreator.create(this, this._hitContainer, _sandParticles, 0, 0, null, null, new Spatial(206,1268));
			_sandParticles.init(this);
			
			if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_LOW){
				_sandStorm = new SandStorm();
				_sandStormEmitter = EmitterCreator.create(this, overlayContainer, _sandStorm);
				_sandStorm.init(this, overlayContainer.width+600, 0, 1400, overlayContainer.height);
				_sandStorm.stream();
			}
			
			_waterChurn = new WaterChurn();
			_waterChurnEmitter = EmitterCreator.create(this, this._hitContainer, _waterChurn, 4698, 1425);
			_waterChurn.init(this);
		}
		
		private function setupEntrance():void
		{
			_hiddenEntrance = EntityUtils.createDisplayEntity(this, _hitContainer["hiddenEntrance"], _hitContainer);
			TimelineUtils.convertClip(this._hitContainer["hiddenEntrance"], this, _hiddenEntrance, null, false);
			
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality;
			BitmapUtils.convertContainer(this._hitContainer["hiddenEntrance"]["entrance"], bitmapQuality);
			
			_entrancePlatform = this.getEntityById("entranceStone");
			_entrancePlat = _entrancePlatform.get(Platform);
			
			_entrancePlatform.remove(Platform);
			
			DisplayUtils.moveToTop(_hitContainer["entranceBlind"]);
			
			_entranceBlind = EntityUtils.createDisplayEntity(this, _hitContainer["entranceBlind"], _hitContainer);
			BitmapUtils.convertContainer(_hitContainer["entranceBlind"], bitmapQuality);
			
			//Display(_entranceBlind.get(Display)).visible = false; // doesn't hide it for some reason??
			
			_hitContainer["entranceBlind"].visible = false;
			
		}
		
		public function finalSequence(...p):void{
			// null zone
			var entity:Entity = super.getEntityById("zoneOpen");
			entity.remove(Zone);
			
			SceneUtil.lockInput(this, true);
			CharUtils.lockControls(player,true,true);
			CharUtils.moveToTarget(this.player, 4650, 1455, true, inPosition);
			
		}
		
		public function inPosition(...p):void{
			
			CharUtils.setDirection(player, true);
			CharUtils.dialogComplete(player, raiseEntrance);
			Dialog(player.get(Dialog)).sayById("openSesame");
			shellApi.triggerEvent("openSesame");
			
		}
		
		public function raiseEntrance(...p):void{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"water_entrance_rising.mp3", 1.4);
			Timeline(_hiddenEntrance.get(Timeline)).gotoAndPlay(2);
			Timeline(_hiddenEntrance.get(Timeline)).handleLabel("end", raised);
			_waterChurn.stream();
			cameraShake();
		}
		
		private function raised():void{
			_waterChurn.stopStream();
			cameraShake();
			_entrancePlatform.add(_entrancePlat);
			
			//Display(_entranceBlind.get(Display)).visible = true;
			_hitContainer["entranceBlind"].visible = true;
			
			goOnPlat();
		}
		
		private function goOnPlat():void{
			CharUtils.moveToTarget(this.player, 4670, 1330, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, goInEntrance));
		}
		
		private function goInEntrance(...p):void{
			CharUtils.moveToTarget(this.player, 4850, 1330, true, inEntrance);
		}
		
		private function inEntrance(...p):void{
			this.removeEntity(player);
			_hitContainer["entranceBlind"].visible = false;
			Timeline(_hiddenEntrance.get(Timeline)).gotoAndPlay("submerge");
			Timeline(_hiddenEntrance.get(Timeline)).handleLabel("done", endScene);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"water_entrance_rising.mp3", 1.4);
			_waterChurn.stream();
			cameraShake();
		}
		
		private function endScene(...p):void
		{
			SceneUtil.lockInput(this, false);
			
			// get medallion and show popup
			_waterChurn.stopStream();
			cameraShake();
			
			// trigger complete island
			//shellApi.completedIsland();
			
			// award medallion
			if(!shellApi.checkHasItem(_events.MEDAL))
			{
				var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID) as ItemGroup;
				shellApi.getItem(_events.MEDAL);
				shellApi.showItem(_events.MEDAL, shellApi.island, medallionReceived);
			}
			else
			{
				medallionReceived();
			}
		}

		private function medallionReceived():void
		{
			shellApi.completedIsland('', showOutroPopup);
		}
		
		private function showOutroPopup(response:PopResponse):void
		{
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
			/*
			var outroPopup:EpisodeEndingPopup = new EpisodeEndingPopup(overlayContainer);
			outroPopup.updateText("You're in the hideout of the 40 thieves! What dangers await?", "to be continued");
			outroPopup.configData("outroPopup.swf", "scenes/arab1/shared/popups/");
			addChildGroup(outroPopup);
			*/
		}
		
		public function easter($num:int = 1):void{
			switch($num){
				case 1:
					Dialog(this.getEntityById("brokeMerchant").get(Dialog)).sayById("warn1");
					break;
				case 2:
					Dialog(this.getEntityById("brokeMerchant").get(Dialog)).sayById("warn2");
					break;
				case 3:
					Dialog(this.getEntityById("brokeMerchant").get(Dialog)).sayById("warn3");
					break;
			}
		}
		
		private function cameraShake():Boolean
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var waveMotion:WaveMotion= cameraEntity.get(WaveMotion);
			
			if(waveMotion != null)
			{
				cameraEntity.remove(WaveMotion);
				var spatialAddition:SpatialAddition = cameraEntity.get(SpatialAddition);
				spatialAddition.y = 0;
				return(false);
			}
			else
			{
				waveMotion = new WaveMotion();
			}
			
			var waveMotionData:WaveMotionData = new WaveMotionData();
			waveMotionData.property = "y";
			waveMotionData.magnitude = 1;
			waveMotionData.rate = 1;
			waveMotion.data.push(waveMotionData);
			cameraEntity.add(waveMotion);
			cameraEntity.add(new SpatialAddition());
			
			if(!super.hasSystem(WaveMotionSystem))
			{
				super.addSystem(new WaveMotionSystem(), SystemPriorities.move);
			}
			
			return(true);
		}
		
		private var _hiddenEntrance:Entity;
		private var _entrancePlatform:Entity;
		
		private var _entranceBlind:Entity;
		
		private var _sandParticles:SandFall;
		private var _sandEmitter:Entity;
		
		private var _sandStorm:SandStorm;
		private var _sandStormEmitter:Entity;
		
		private var _waterChurn:WaterChurn;
		private var _waterChurnEmitter:Entity;
		
		private var _dias:Entity;
		private var _events:Arab1Events;
		
		private var _placedItem:String;
		//private var _smokeBombGroup:SmokeBombGroup;
		private var _flag1:Entity;
		private var _flag2:Entity;
		private var _entrancePlat:Platform;
		private var _camel:Entity;
		private var _camelCreator:CamelCreator;
		private var _haveCamel:Boolean;
		private var _bomb:Entity;
		private var _puddle:Entity;
	}
}