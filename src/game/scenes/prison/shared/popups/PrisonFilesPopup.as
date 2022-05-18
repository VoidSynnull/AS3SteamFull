package game.scenes.prison.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class PrisonFilesPopup extends Popup
	{
		public function PrisonFilesPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.groupPrefix = "scenes/prison/shared/popups/";
			this.pauseParent = true;
			this.darkenBackground = true;
			this.darkenAlpha = .75;
			this.autoOpen = true;
			
			load();
		}
		
		override public function load():void
		{
			this.loadFiles([shellApi.profileManager.active.gender + "/" + GameScene.NPCS_FILE_NAME, "prisonFilesPopup.swf"], false, true, loaded);
		}
		
		override public function loaded():void
		{
			this.screen = getAsset("prisonFilesPopup.swf", true) as MovieClip;
			this.letterbox(screen.content, new Rectangle(0, 0, 465, 500), false);
			
			_currentPage = 0;
			var topPage:Entity = EntityUtils.createSpatialEntity(this, screen.content.topPage);
			InteractionCreator.addToEntity(topPage, [InteractionCreator.CLICK]).click.add(nextPage);
			ToolTipCreator.addToEntity(topPage);
			
			_textEntity = TimelineUtils.convertClip(screen.content.infoText, this, null, null, false);
			_backPages = TimelineUtils.convertClip(screen.content.pages, this, null, null, false);
			
			setupNPCs();
			
			super.loadCloseButton();
		}
		
		private function nextPage(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "paper_flap_03.mp3");
			_currentPage++;
			var nextNum:Number = _currentPage%NPC_ORDER.length;
			var prev:Number = nextNum > 0 ? nextNum - 1 : NPC_ORDER.length - 1;
			
			_textEntity.get(Timeline).gotoAndStop(nextNum);
			_backPages.get(Timeline).gotoAndStop(nextNum);			
			getEntityById(NPC_ORDER[prev]).get(Display).visible = false;			
			getEntityById(NPC_ORDER[nextNum]).get(Display).visible = true;
			
			if(NPC_ORDER[nextNum] == "playerNPC")
			{
				_textfield.visible = true;
			}
			else
			{
				_textfield.visible = false;
			}
		}
		
		private function setupNPCs():void
		{
			_characterGroup = new CharacterGroup();
			_characterGroup.setupGroup(this, screen, super.getData(shellApi.profileManager.active.gender + "/" + GameScene.NPCS_FILE_NAME), allCharactersLoaded);			
		}		
		
		private function allCharactersLoaded():void
		{	
			var playerNPC:Entity = _characterGroup.createNpcPlayer(npcPlayerCreated, null, new Point(0, 75), "portrait");			
			playerNPC.add(new Id("playerNPC"));
		}
		
		private function npcPlayerCreated(...args):void
		{
			getEntityById("playerNPC").get(Spatial).scale = .5;
			SkinUtils.setEyeStates(getEntityById("playerNPC"), "open_still");
			
			for(var i:int = 0; i < NPC_ORDER.length; i++)
			{				
				var npc:Entity = getEntityById(NPC_ORDER[i]);
				screen.content.topPage.npcHolder.addChild(npc.get(Display).displayObject);
				
				if(i > 0)
				{
					npc.get(Display).visible = false;
				}	
			}
			
			super.loaded();
			
			_textfield = new TextField();
			_textfield.embedFonts = true;
			_textfield.wordWrap = false;
			_textfield.multiline = false;
			_textfield.defaultTextFormat = new TextFormat("Chaparral Pro", 19, 0x485F6E);
			_textfield.autoSize = TextFieldAutoSize.LEFT;
			_textfield.text = shellApi.profileManager.active.avatarName;
			_textfield.x = 255;
			_textfield.y = 125;
			screen.content.addChild(_textfield);
			_textfield.visible = false;
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "paper_flap_04.mp3");
		}
		
		private var _characterGroup:CharacterGroup;
		private var _currentPage:uint;
		private var _textEntity:Entity;
		private var _backPages:Entity;
		private var _textfield:TextField;
		
		private const NPC_ORDER:Array = ["bigTuna", "florian", "playerNPC", "nostrand", "patches", "les", "sal", "flambe"];
	}
}