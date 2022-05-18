package game.scenes.arab2.treasureKeep
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.motion.Draggable;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.arab2.Arab2Events;
	import game.systems.motion.DraggableSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class LampPopup extends Popup
	{
		private const GRAB_SOUND:String = SoundManager.EFFECTS_PATH + "single_stone_impact_03.mp3";
		private const PLACE_SOUND:String = SoundManager.EFFECTS_PATH + "single_stone_impact_03.mp3";
		private const SUCCES_SOUND:String = SoundManager.EFFECTS_PATH + "points_ping_04c.mp3";
		private const FAIL_SOUND:String = SoundManager.EFFECTS_PATH + "alarm_04.mp3";
		
		
		private var sucess:Boolean = false;
		
		private var _events:Arab2Events;
		
		public var completeSignal:Signal;
		private var _lamps:Array;
		private var _TargetLamp:Entity;
		private var vizier:Entity;
		private var vizierDialog:Dialog; 
		private var dropZone:Entity;
		
		
		
		
		public function LampPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			//super.transitionIn = new TransitionData();
			//super.transitionIn.duration = .3;
			//super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			//super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/arab2/treasureKeep/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
				super.loadFiles(["lamp_popup_low.swf", "popup/" + GameScene.DIALOG_FILE_NAME, "popup/" + GameScene.NPCS_FILE_NAME]);
			}else{
				super.loadFiles(["lamp_popup.swf", "popup/" + GameScene.DIALOG_FILE_NAME, "popup/" + GameScene.NPCS_FILE_NAME]);
			}
		}
		
		// all assets ready
		override public function loaded():void
		{				
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
				super.screen = super.getAsset("lamp_popup_low.swf", true) as MovieClip;
			}
			else{
				super.screen = super.getAsset("lamp_popup.swf", true) as MovieClip;
			}
			
			//this.layout.centerUI( super.screen );
			this.letterbox(screen.content, new Rectangle(0, 0, 960, 640));
			
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			
			setupCharacter();
			
			setupPuzzle();
			
			
			super.loadCloseButton();
			
			super.loaded();
		}
		
		public function setupCharacter():void
		{
			//load vizier
			var characterGroup:CharacterGroup = new CharacterGroup();
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			
			characterGroup.setupGroup( this, super.screen.content, super.getData( "popup/" + GameScene.NPCS_FILE_NAME ), allCharactersLoaded );				
			characterDialogGroup.setupGroup( this, super.getData( "popup/" + GameScene.DIALOG_FILE_NAME ), super.screen.content );
		}
		
		protected function allCharactersLoaded():void
		{
			vizier = super.getEntityById( "vizier2" );
			vizierDialog = vizier.get(Dialog);
			vizierDialog.faceSpeaker = false;
			vizierDialog.dialogPositionPercents.x = 1.3;
			vizierDialog.container = this.screen.content;
			DisplayUtils.moveToTop(vizier.get(Display).displayObject);
			vizier.remove(SceneInteraction);
			vizier.remove(Interaction);
			lockInput();
			SceneUtil.addTimedEvent(this, new TimedEvent(1.1,1,Command.create(vizierDialog.sayById,"intro")));
			vizierDialog.complete.removeAll();
			vizierDialog.complete.addOnce(unlockInput);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
				Timeline(vizier.get(Timeline)).handleLabel("startBreath",Command.create(CharUtils.freeze,vizier));
			}
		}
		
		private function setupPuzzle():void
		{
			addSystem(new DraggableSystem());
			
			var lampCount:int;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM){
				lampCount = 8;
			}else{
				lampCount = 11;
			}
			var lampA:Entity;
			var lampB:Entity;
			// lamp we want
			_TargetLamp = makeLamp("targetLamp");
			_lamps = new Array();
			// decoy lamps
			for (var i:int = 0; i < lampCount; i++) 
			{	
				lampA = makeLamp("lamp" + i + "a");
				lampB = makeLamp("lamp" + i + "b");
			}
			
			var clip:MovieClip = screen.content["Z"];
			dropZone = EntityUtils.createSpatialEntity(this, clip);
			dropZone.add(new Sleep(false,true))
			Display(dropZone.get(Display)).visible = false;
			Display(dropZone.get(Display)).alpha = 0;
			Display(dropZone.get(Display)).moveToFront();
		}
		
		private function makeLamp(id:String):Entity
		{
			var clip:MovieClip = screen.content[id];
			super.convertToBitmapSprite(clip.l,null,true,PerformanceUtils.defaultBitmapQuality);
			// a and b lamp of each type, share bitmap data
			var lamp:Entity = EntityUtils.createSpatialEntity(this, clip);
			lamp.add(new Id(id));
			// add dragging
			InteractionCreator.addToEntity(lamp,[InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
			var dragable:Draggable = new Draggable();
			dragable.drag.add(lampGrabbed);
			dragable.drop.add(lampDropped);
			lamp.add(dragable);	
			ToolTipCreator.addUIRollover(lamp);	
			
			var sp:Spatial = lamp.get(Spatial);
			lamp.add(new OriginPoint(sp.x,sp.y,sp.rotation));
			return lamp;
		}
		
		private function lampDropped(lamp:Entity):void
		{
			// test if dropped on vizier
			var vizDisplay:Display = dropZone.get(Display);
			var lampPos:Spatial = lamp.get(Spatial);
			if(vizDisplay.displayObject.hitTestPoint(lampPos.x, lampPos.y) || GeomUtils.spatialDistance(lampPos,dropZone.get(Spatial)) < 150){
				lockInput();
				// verify the lamp
				var id:String = lamp.get(Id).id;
				if(id == "targetLamp"){
					// win
					vizierDialog.sayById("success");
					vizierDialog.complete.addOnce(deliverResult);
					sucess = true;
					TweenUtils.entityTo(lamp, Spatial, 1, {x:525, y:180});
					AudioUtils.play(this, SUCCES_SOUND, 1.7, false);
				}
				else if(id.substr(0,4) == "lamp"){
					// fail, put back
					failResponse();
					AudioUtils.play(this, FAIL_SOUND, 1.7, false);
					var origin:OriginPoint = OriginPoint(lamp.get(OriginPoint));
					TweenUtils.entityTo(lamp, Spatial, 0.5, {x:origin.x, y:origin.y});
				}
				vizierDialog.complete.addOnce(Command.create(checkResult,lamp));
			}
			else{
				// move to nearest platform on drop
				var spatial:Spatial = lamp.get(Spatial);
				if(spatial.y > 332){
					//bottom
					if(spatial.x < 208){
						TweenUtils.entityTo(lamp, Spatial, 0.4, {x:208, y:522, ease:Linear.easeIn});
					}
					else{
						TweenUtils.entityTo(lamp, Spatial, 0.4, {x:spatial.x, y:522, ease:Linear.easeIn});
					}
				}else{
					// top
					if(spatial.x < 208){
						TweenUtils.entityTo(lamp, Spatial, 0.4, {x:208, y:332, ease:Linear.easeIn});
					}
					else{
						TweenUtils.entityTo(lamp, Spatial, 0.4, {x:spatial.x, y:332, ease:Linear.easeIn});
					}				
				}
			}
			AudioUtils.play(this, PLACE_SOUND, 1.7, false);
		}
		
		private function failResponse():void
		{
			// random comment machine!
			vizierDialog.sayById("nope"+GeomUtils.randomInt(0,4));
			vizierDialog.complete.addOnce(unlockInput);
		}
		
		private function lockInput(...p):void
		{
			SceneUtil.lockInput(this, true, false);
		}
		private function unlockInput(...p):void
		{
			SceneUtil.lockInput(this, false, false);
		}
		
		private function lampGrabbed(lamp:Entity):void
		{
			AudioUtils.play(this, GRAB_SOUND, 1.5, false);
		}
		
		private function checkResult(junk:*,lamp:Entity):void
		{
			// if marked sucess, exit popup
			if(sucess){
				SceneUtil.addTimedEvent(this, new TimedEvent(1.8,1,deliverResult));
			}
		}
		
		// fire signal and exit
		private function deliverResult(...p):void
		{
			this.popupRemoved.add(Command.create(completeSignal.dispatch,sucess));
			close(true);
		}
		
		
		override public function close(removeOnClose:Boolean=true, onCloseHandler:Function=null):void
		{
			//SceneUtil.lockInput(this, false);
			super.close(removeOnClose,onCloseHandler);
		}
	}
}