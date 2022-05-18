package game.scenes.arab3.vizierRoom.popups
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.character.LookData;
	import game.data.ui.TransitionData;
	import game.scene.template.CharacterDialogGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scenes.arab3.Arab3Events;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	public class BookshelfPopup extends Popup
	{
		private var _events:Arab3Events;
		private var mainBook:Entity;
		
		private var player2:Entity;
		private var player2Dialog:Dialog; 
		
		public function BookshelfPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			_events = new Arab3Events();
			
			this.id 				= "BookshelfPopup";
			this.groupPrefix 		= "scenes/arab3/vizierRoom/popups/";
			//this.screenAsset 		= "bookshelfPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			//this.transitionIn 			= new TransitionData();
			//this.transitionIn.duration 	= 0.3;
			//this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			//this.transitionIn.endPos 	= new Point(0, 0);
			//this.transitionIn.ease 		= Sine.easeInOut;
			//this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			//this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			
			super.loadFiles(["bookshelfPopup.swf", GameScene.DIALOG_FILE_NAME, GameScene.NPCS_FILE_NAME]);
		}
		
		override public function loaded():void
		{		
			super.screen = super.getAsset("bookshelfPopup.swf", true) as MovieClip;
			
			this.setupBookButtons();
			
			setupCharacter();
			
			this.setupContent();
			super.loadCloseButton();
			
			super.loaded();
		}
		
		public function setupCharacter():void
		{
			//load vizier
			var characterGroup:CharacterGroup = new CharacterGroup();
			var characterDialogGroup:CharacterDialogGroup = new CharacterDialogGroup();
			
			characterGroup.setupGroup( this, super.screen.content, super.getData( GameScene.NPCS_FILE_NAME ), allCharactersLoaded );		
			characterDialogGroup.setupGroup( this, super.getData( GameScene.DIALOG_FILE_NAME ), super.screen.content );
		}
		
		protected function allCharactersLoaded():void
		{
			player2 = super.getEntityById( "player2" );
			var look:LookData = SkinUtils.getLook(this.shellApi.player);
			SkinUtils.applyLook(player2, look, true);	
			
			/*CharUtils.getPart(player2, CharUtils.PACK).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.ARM_BACK).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.HAND_BACK).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.LEG_BACK).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.FOOT_BACK).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.LEG_FRONT).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.FOOT_FRONT).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.ARM_FRONT).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.HAND_FRONT).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.ITEM).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.BODY_PART).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.PANTS_PART).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.SHIRT_PART).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.OVERPANTS_PART).get(Display).visible = false;
			CharUtils.getPart(player2, CharUtils.OVERSHIRT_PART).get(Display).visible = false;
			
			SkinUtils.hideSkinParts(player2, [SkinUtils.PANTS, 
											SkinUtils.SHIRT, 
											SkinUtils.OVERPANTS, 
											SkinUtils.OVERSHIRT, 
											SkinUtils.ITEM, 
											SkinUtils.ITEM2,
											SkinUtils.PACK,
											SkinUtils.BODY,
											SkinUtils.FOOT1,
											SkinUtils.FOOT2,
											SkinUtils.HAND1,
											SkinUtils.HAND2], true);*/
			
			
			CharUtils.getTimeline(player2).stop();
			
			player2Dialog = player2.get(Dialog);
			player2Dialog.faceSpeaker = false;
			player2Dialog.container = this.screen.content;
			DisplayUtils.moveToTop(player2.get(Display).displayObject);
			
			player2.remove(SceneInteraction);
			player2.remove(Interaction);
			ToolTipCreator.removeFromEntity(player2);
			
			player2.get(Display).alpha = 0;
			player2.get(Spatial).x = 70;
			
			//SceneUtil.addTimedEvent(this, new TimedEvent(1.1,1,Command.create(player2Dialog.sayById,"intro")));			
		}
		
		private function lockInput(...p):void
		{
			SceneUtil.lockInput(this, true, false);
		}
		private function unlockInput(...p):void
		{
			SceneUtil.lockInput(this, false, false);
			TweenUtils.globalTo(this, player2.get(Display), 0.1, {alpha:0, ease:Sine.easeInOut}, "playerOff");
		}
		
		private function setupBookButtons():void
		{
			//main book
			mainBook = ButtonCreator.createButtonEntity(this.screen.content.book, this, onBookClick, null, null, null, true, true);	
			mainBook.add(new Id("mainBook"));
			
			var entity:Entity;
			for (var i:uint = 1; i <= 8; i++ ) {
				entity = ButtonCreator.createButtonEntity(this.screen.content["b"+i], this, onBookClick, null, null, null, true, true);	
				entity.add(new Id("b"+i));
			}
		}
		
		private function onBookClick(entity:Entity):void
		{
			player2Dialog.complete.removeAll();
			
			TweenUtils.globalTo(this, player2.get(Display), 0.1, {alpha:1, ease:Sine.easeInOut}, "playerOn");
			
			lockInput();
			
			var id:String = entity.get(Id).id;
			
			switch( id ) {
				case "mainBook":
					if(!shellApi.checkHasItem(_events.INSTRUCTIONS)){
						player2Dialog.complete.addOnce(getInstructions);
						player2Dialog.sayById("mainbook");
					} else {
						player2Dialog.complete.addOnce(unlockInput);
						player2Dialog.sayById("mainbook2");
					}
					break;
				default:
					player2Dialog.complete.addOnce(unlockInput);
					player2Dialog.sayById(id);
			}
		}
		
		private function getInstructions(...p):void {
			unlockInput();
			shellApi.triggerEvent("getInstructions");
		}
		
		private function setupContent():void
		{
			var content:MovieClip = this.screen.content;
			
			//content.x *= this.shellApi.viewportWidth / content.width / 2;
			//content.y *= this.shellApi.viewportHeight / content.height / 2;
			
			DisplayUtils.fitDisplayToScreen(this, content, new Point(960, 640));
		}
	}
}