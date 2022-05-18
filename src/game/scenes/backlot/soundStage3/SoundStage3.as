package game.scenes.backlot.soundStage3
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.timeline.Timeline;
	import game.components.entity.character.part.Part;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Salute;
	import game.data.game.GameEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.shared.popups.TrainConstruction;
	import game.scenes.backlot.soundStage3Chase.SoundStage3Chase;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class SoundStage3 extends PlatformerGameScene
	{
		public function SoundStage3()
		{
			super();
		}
		
		private var backlot:BacklotEvents;
		private var trainConstruction:TrainConstruction;
		
		private var hero:Entity;
		private var villain:Entity;
		private var sophia1:Entity;
		private var sophia2:Entity;
		private var carson:Entity
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/soundStage3/";
			
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
			backlot = events as BacklotEvents;
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			setUpPropTrigger();
			setUpHats();
			setUpNpcs();
			setUpTrain();
			setUpBackDrop();
		}
		
		private function setUpBackDrop():void
		{
			var backDrop:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["backdropAnime"],_hitContainer);
			var audioRange:AudioRange = new AudioRange(1000,.1,1,Quad.easeIn);
			backDrop.add(new Audio()).add(audioRange).add(new Id("backDrop"));
			Audio(backDrop.get(Audio)).play("effects/treadmill_servo_01_L.mp3",true,SoundModifier.POSITION);
			Display(backDrop.get(Display)).moveToBack();
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			trace(event);
			if(event == backlot.MADE_TRAIN_PROP)
			{
				makeTrain();
			}
			if(event == backlot.THATS_A_TRAIN)
			{
				SceneUtil.setCameraTarget(this, sophia1);
				Dialog(sophia1.get(Dialog)).sayById("fresh paint");
			}
			if(event == backlot.PAINT_TRAIN)
			{
				paintTrain();
			}
			if(event == backlot.PAINTED_TRAIN)
			{
				Dialog(sophia1.get(Dialog)).sayById("see");
			}
			if(event == backlot.FINISHED_TALKING)
			{
				SceneUtil.lockInput(this, false);
				SceneUtil.setCameraTarget(this, player);
			}
			if(event == backlot.START_WESTERN_FILM)
			{
				shellApi.loadScene(SoundStage3Chase);
			}
		}
		
		private function makeTrain():void
		{
			SceneUtil.lockInput(this);
			Display(getEntityById("train").get(Display)).visible = true;
			Dialog(player.get(Dialog)).sayById("dont look like train");
			SkinUtils.setSkinPart(sophia1, SkinUtils.ITEM,"brush", false);
			removePropInteraction();
		}
		
		private function removePropInteraction():void
		{
			removeEntity(getEntityById("props"));
			Dialog(sophia1.get(Dialog)).setCurrentById("grab hats");
		}
		
		private function paintTrain():void
		{
			CharUtils.setAnim(sophia1, Salute);
			var train:Entity = getEntityById("train");
			Audio(train.get(Audio)).play("effects/sparkle_01.mp3");
			Timeline(train.get(Timeline)).play();
		}
		
		private function setUpTrain():void
		{
			var train:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["mcTrain"], _hitContainer);
			train.add(new Audio()).add(new Id("train"));
			TimelineUtils.convertClip(_hitContainer["mcTrain"], this, train, null, false);
			var timeline:Timeline = train.get(Timeline);
			timeline.handleLabel("ending",Command.create(trainTimeline, timeline));
			Display(train.get(Display)).visible = false;
			
			if(shellApi.checkEvent(backlot.PAINTED_TRAIN))
				removeEntity(train);
		}
		
		private function trainTimeline(timeline:Timeline):void
		{
			timeline.gotoAndStop(timeline.currentIndex);
			var tween:Tween = new Tween();
			tween.to(getEntityById("train").get(Spatial), 5, {x:0, onComplete:paintedTrain });
			getEntityById("train").add(tween);
		}
		
		private function paintedTrain():void
		{
			shellApi.triggerEvent(backlot.PAINTED_TRAIN, true);
			removeEntity(getEntityById("train"));
			getEntityById("blackHat").get(Display).visible = true;
			getEntityById("whiteHat").get(Display).visible = true;
		}
		
		private function setUpNpcs():void
		{
			hero = getEntityById("char2");
			villain = getEntityById("char3");
			sophia1 = getEntityById("char1");
			sophia2 = getEntityById("char4");
			carson = getEntityById("char5");
			
			if(!shellApi.checkEvent(backlot.FOUND_HERO))
				removeEntity(hero);
			
			if(!shellApi.checkEvent(backlot.FOUND_VILLAIN))
				removeEntity(villain);
			
			if(!shellApi.checkEvent(backlot.READY_TO_ACT))
			{
				if(!shellApi.checkEvent(backlot.MADE_TRAIN_PROP))
					Dialog(sophia1.get(Dialog)).setCurrentById("noshow");
				else
					Dialog(sophia1.get(Dialog)).setCurrentById("grab hats");
				removeEntity(carson);
				removeEntity(sophia2);
			}
			else
			{
				removeEntity(sophia1);
				if(shellApi.checkEvent(backlot.COMPLETE_STAGE_3))
				{
					Dialog(hero.get(Dialog)).setCurrentById("whew");
					Dialog(villain.get(Dialog)).setCurrentById("connected");
					Dialog(sophia2.get(Dialog)).setCurrentById("great work");
				}
				else
				{
					Dialog(hero.get(Dialog)).setCurrentById("finally");
					Dialog(villain.get(Dialog)).setCurrentById("at last");
					Dialog(sophia2.get(Dialog)).setCurrentById("need");
				}
				if(shellApi.checkEvent(backlot.COMPLETED_ALL_STAGES))
					Dialog(carson.get(Dialog)).setCurrentById("meet");
				else
					removeEntity(carson);
			}
		}
		
		private function setUpHats():void
		{
			var whiteHat:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["mcWhiteHat"], _hitContainer);
			whiteHat.add(new Id("whiteHat"));
			whiteHat.add(new SceneInteraction());
			InteractionCreator.addToEntity(whiteHat,[InteractionCreator.CLICK],this._hitContainer["mcWhiteHat"]);
			var interaction:SceneInteraction = whiteHat.get(SceneInteraction);
			interaction.reached.add(pickUpHat);
			ToolTipCreator.addToEntity(whiteHat);
			
			if(shellApi.checkEvent(GameEvent.GOT_ITEM + backlot.WHITE_HAT))
				removeEntity(whiteHat);
			else
			{
				if(!shellApi.checkEvent(backlot.PAINTED_TRAIN))
					whiteHat.get(Display).visible = false;
			}
			
			var blackHat:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["mcBlackHat"], _hitContainer);
			blackHat.add(new Id("blackHat"));
			blackHat.add(new SceneInteraction());
			InteractionCreator.addToEntity(blackHat,[InteractionCreator.CLICK],this._hitContainer["mcBlackHat"]);
			interaction = blackHat.get(SceneInteraction);
			interaction.reached.add(pickUpHat);
			ToolTipCreator.addToEntity(blackHat);
			
			if(shellApi.checkEvent(GameEvent.GOT_ITEM + backlot.BLACK_HAT))
				removeEntity(blackHat);
			else
			{
				if(!shellApi.checkEvent(backlot.PAINTED_TRAIN))
					blackHat.get(Display).visible = false;
			}
		}
		
		private function pickUpHat(player:Entity, hat:Entity):void
		{
			shellApi.getItem(hat.get(Id).id, null, true);
			removeEntity(hat);
		}
		
		private function setUpPropTrigger():void
		{
			var props:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["mcProps"], _hitContainer);
			props.add(new Id("props"));
			props.get(Display).alpha = 0;
			var interaction:Interaction = InteractionCreator.addToEntity(props,[InteractionCreator.CLICK],this._hitContainer["mcProps"]);
			interaction.click.add(clickProps);
			ToolTipCreator.addToEntity(props);
			//if(shellApi.checkEvent(backlot.PAINTED_TRAIN))
			//	removeEntity(props);
		}
		
		private function clickProps(props:Entity):void
		{
			trainConstruction = super.addChildGroup( new TrainConstruction( super.overlayContainer )) as TrainConstruction;
		}
	}
}