package game.scenes.prison.prisonPromo
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookData;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.prison.mainStreet.MainStreet;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.SetDirectionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.ui.hud.HudPopBrowser;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class PrisonPromo extends PlatformerGameScene
	{
		private var guardZone:Entity;
		private var ratchet:Entity;
		private var dog:Entity;
		private var nightingale:Entity;
		private var sparky:Entity;
		private var mobileSign:Entity;
		private var prisoner1:Entity;
		private var prisoner2:Entity;
		private var prisoner3:Entity;
		private var webSign:Entity;
		
		public function PrisonPromo()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/prison/prisonPromo/";
			
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
			/*
			Drew - When the promo for Prison is done, this shouldn't be a "valid"
			scene anymore. We're going to force people onto MainStreet if their
			last scene was here. Both mobile and web now redirect.
			*/
			this.shellApi.loadScene(MainStreet);
			return;
			
			super.loaded();
			
			shellApi.eventTriggered.add(eventTriggered);
			
			setupPromo();
		}
		
		protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			switch(event)
			{
				case "night_leaves":
				{
					guardLeaves();
					break;
				}
			}
		}
		
		private function giveBird(...p):void
		{
			
		}
		
		private function giveCostume(...p):void
		{
			var look:LookData = SkinUtils.getPlayerLook(this);
			if(look.getAspect(SkinUtils.GENDER).value == "male"){
				shellApi.getItem("3476","store",true);
			}else{
				shellApi.getItem("3477","store",true);
			}
		} 
		
		private function guardLeaves():void
		{
			CharUtils.setAnim(nightingale, Stand, false,0,0,true);				
			CharUtils.moveToTarget(nightingale, 5250, 1600, false, guardLeft);
		}
		
		private function guardLeft(...p):void
		{
			removeEntity(nightingale);
		}
		
		public function setupPromo():void
		{			
			// gender specifics
			var look:LookData = SkinUtils.getPlayerLook(this);
			if(look.getAspect(SkinUtils.GENDER).value == "male"){
				ratchet = getEntityById("ratchetM");
				nightingale = getEntityById("nightingaleM");
				removeEntity(getEntityById("ratchetF"));
				removeEntity(getEntityById("nightingaleF"));
				prisoner1 = getEntityById("prisoner1");
				prisoner2 = getEntityById("prisoner2");	
				prisoner3 = getEntityById("prisoner3");
				removeEntity(getEntityById("prisoner1F"));
				removeEntity(getEntityById("prisoner2F"));	
				removeEntity(getEntityById("prisoner3F"));
			}else{
				ratchet = getEntityById("ratchetF");
				nightingale = getEntityById("nightingaleF");
				removeEntity(getEntityById("ratchetM"));
				removeEntity(getEntityById("nightingaleM"));
				prisoner1 = getEntityById("prisoner1F");
				prisoner2 = getEntityById("prisoner2F");	
				prisoner3 = getEntityById("prisoner3F");
				removeEntity(getEntityById("prisoner1"));
				removeEntity(getEntityById("prisoner2"));	
				removeEntity(getEntityById("prisoner3"));
			}
			
			if(shellApi.checkHasItem("3475","store")){
				removeEntity(nightingale);
			}			
			// ratchet and dog intercept you if you walk too close
			setupDog();
			guardZone = getEntityById("guardZone");
			if(!shellApi.checkHasItem("3476","store") && !shellApi.checkHasItem("3477","store")){
				var zone:Zone = guardZone.get(Zone);
				zone.entered.addOnce(stopPlayer);
			}
			
			mobileSign = EntityUtils.createSpatialEntity(this,_hitContainer["mobileSign"]);
			webSign = EntityUtils.createSpatialEntity(this,_hitContainer["webSign"]);
			if(PlatformUtils.isDesktop){
				// show members promotion
				var inter:Interaction = InteractionCreator.addToEntity(webSign,[InteractionCreator.CLICK]);
				inter.click.add(openMemeberLink);
				Display(mobileSign.get(Display)).visible = false;
				Display(webSign.get(Display)).visible = true;
				ToolTipCreator.addToEntity(webSign);
			}else{				
				// show mobile coming soon		
				Display(mobileSign.get(Display)).visible = true;
				Display(webSign.get(Display)).visible = false;
			}
			
			var seagull:Entity = EntityUtils.createMovingTimelineEntity(this, _hitContainer["seagull"],null,true);
			seagull.add(new Id("seagull"));
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(seagull));
			Timeline(seagull.get(Timeline)).handleLabel("squak",birdSound,false);
			
			//SOUNDS			
			Timeline(prisoner1.get(Timeline)).handleLabel("reset",shovelSound,false);
			Timeline(prisoner2.get(Timeline)).handleLabel("impact",pickSound,false);
			Timeline(prisoner3.get(Timeline)).handleLabel("impact",hammerSound,false);
		}
		
		private function openMemeberLink(...p):void
		{
			HudPopBrowser.buyMembership(super.shellApi, "source=POP_img_GetMembership_MainStreetComingSoon-pop&medium=Display&campaign=PelicanRockIsland");
		}
		
		private function birdSound(...p):void
		{
			AudioUtils.playSoundFromEntity(getEntityById("seagull"), SoundManager.EFFECTS_PATH+"seagull_squawk_01.mp3");
		}
		
		private function shovelSound(...p):void
		{
			AudioUtils.playSoundFromEntity(prisoner1, SoundManager.EFFECTS_PATH+"shovel_dirt_01.mp3");
		}
		
		private function pickSound(...p):void
		{
			AudioUtils.playSoundFromEntity(prisoner2, SoundManager.EFFECTS_PATH+"dirt_break_01.mp3");
		}
		
		private function hammerSound(...p):void
		{
			AudioUtils.playSoundFromEntity(prisoner3, SoundManager.EFFECTS_PATH+"hammering_on_wood_01.mp3");
		}
		
		private function setupDog():void
		{
			// ratchet's dog
			sparky = EntityUtils.createMovingTimelineEntity(this, _hitContainer["sparky"], null, true);
			if(shellApi.checkHasItem("3476","store") || shellApi.checkHasItem("3477","store")){
				removeEntity(sparky);
			}
		}
				
		private function stopPlayer(...p):void
		{
			SceneUtil.lockInput(this,true);
			MotionUtils.zeroMotion(player);
			CharUtils.moveToTarget(player,ratchet.get(Spatial).x + 330, ratchet.get(Spatial).y,true,startGuarDogConv,new Point(50,100)).validCharStates = new <String>[CharacterState.STAND];
			var ignoreHits:ValidHit = new ValidHit("bounce");
			ignoreHits.inverse = true;
			player.add(ignoreHits);		
		}
			
		private function startGuarDogConv(...p):void
		{
			//dog barks and animates before guard stops you
			var actions:ActionChain = new ActionChain(this);
			actions.lockInput = true;
			
			actions.addAction(new SetDirectionAction(player, false));
			actions.addAction(new WaitAction(0.5));
			actions.addAction(new TimelineAction(sparky,"bark","ending",false)).noWait = true;
			actions.addAction(new AudioAction(sparky,SoundManager.EFFECTS_PATH+"dog_barking_02.mp3",1200,1.1,1.5,Linear.easeInOut)).noWait = true;
			actions.addAction(new AnimationAction(player, Grief,"",0,false)).noWait = true;
			actions.addAction(new WaitAction(4.2));
			actions.addAction(new TimelineAction(sparky,"idle","ending",false)).noWait = true;
			actions.addAction(new TalkAction(ratchet,"hold"));
			actions.addAction(new MoveAction(player,new Point(ratchet.get(Spatial).x + 120, player.get(Spatial).y),new Point(50,100)));
			actions.addAction(new SetDirectionAction(player, false));
			actions.addAction(new CallFunctionAction(EntityUtils.position,player,ratchet.get(Spatial).x + 120, player.get(Spatial).y+20));
			actions.addAction(new TalkAction(player, "what"));
			actions.addAction(new TalkAction(ratchet, "dog"));
			actions.addAction(new TalkAction(player, "wrong"));
			actions.addAction(new TalkAction(ratchet, "all"));
			actions.addAction(new TalkAction(ratchet, "wear"));
			actions.addAction(new CallFunctionAction(giveCostume));	
			actions.addAction(new TalkAction(ratchet, "follow"));
			actions.addAction(new CallFunctionAction(removeEntity,sparky));
			actions.addAction(new AudioAction(player, SoundManager.EFFECTS_PATH+"chomp_01.mp3"));
			actions.addAction(new SetSkinAction(player,SkinUtils.PANTS,"pr_dogpromo"));
			
			actions.execute(doneTalking);
		}
		
		private function doneTalking(...p):void
		{
			SceneUtil.lockInput(this,false);
			player.remove(ValidHit);	
		}		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}