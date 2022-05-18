package game.ui.multiplayer
{
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.UIView;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.ui.Button;
	import game.components.ui.ToolTipActive;
	import game.creators.ui.ButtonCreator;
	import game.data.display.BitmapWrapper;
	import game.scene.template.SFSceneGroup;
	import game.scene.template.SceneUIGroup;
	import game.systems.entity.character.states.CharacterState;
	import game.ui.hud.Hud;
	import game.ui.multiplayer.chat.Chat;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.utils.Maths;

	public class Emotes extends UIView
	{
		public static var GROUP_ID:String					 = "emotes";
		
		protected static const BUTTON_OFFSET:int = 10;
		protected static const BUTTON_BUFFER:int = 80;
		
		protected static var ICON_WIDTH:Number;
		protected static var ICON_HEIGHT:Number;
		
		public var validEmoteStates:Array = [CharacterState.STAND, CharacterState.WALK];
		
		public function Emotes($sfSceneGroup:SFSceneGroup)
		{
			_sfSceneGroup = $sfSceneGroup;
			super();
			super.id = GROUP_ID;
		}
		
		override public function added():void
		{
			shellApi.loadFile(shellApi.assetPrefix + "scenes/hub/starcade/emotes/emotes.swf", emotesMenu);
		}
		
		override public function destroy():void{
			
			_hud.openingHud.remove(onHudOpen);
			_hud = null;
			
			_menuIcons = null;
			_emoteIcons = null;
			_sayIcons = null;
			_thinkIcons = null;
			_gameIcons = null;
			
			thinkIconData = null;
			gameIconData = null;
			
			_shownIcons = null;
			
			_backgroundTint = null;
			
			
			super.destroy();
		}
		
		private function emotesMenu(clip:MovieClip):void{
			
			_sfSceneGroup.scene.overlayContainer.addChild(clip);
			
			// create background
			_background = new Entity();
			var bgClip:MovieClip = new MovieClip();
			bgClip.graphics.beginFill(0x000000);
			bgClip.graphics.drawRect(0, 0, shellApi.viewportWidth, shellApi.viewportHeight);
			bgClip.graphics.endFill();
			
			_backgroundTint = super.convertToBitmap( bgClip );
			bgClip.alpha = .4;
			_sfSceneGroup.scene.overlayContainer.addChildAt(bgClip, 0);
			//super.groupContainer.addChildAt(bgClip, 0);
			_background.add( new Display( bgClip ) );
			bgClip.visible = false;
			var interaction:Interaction = InteractionCreator.addToEntity( _background, [ InteractionCreator.CLICK ], bgClip );
			interaction.click.add( onBGClicked );
			super.addEntity( _background );
			
			// add HUD signal listeners
			// TODO :: should be able to just get Hud group directly - bard
			var uiGroup:SceneUIGroup = _sfSceneGroup.scene.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup;
			_hud = uiGroup.hud as Hud;
			_hud.openingHud.add(onHudOpen);
			
			// add CHAT signal listeners
			var chatGroup:Chat = _sfSceneGroup.getGroupById(Chat.GROUP_ID) as Chat;
			if(chatGroup)
				chatGroup.chatOpen.add(onHudOpen);
			
			// main button
			_emotesButton = ButtonCreator.createButtonEntity(clip["button_emotes"], this, onEmoteMenu, null, null, null, false);
			// if suppressing icons in clubhouse, then hide
			if (_sfSceneGroup.suppressIconsOnInit)
			{
				showEmotes(false);
			}
			
			var spatial:Spatial = _emotesButton.get(Spatial);
			spatial.x = shellApi.viewportWidth - ( BUTTON_BUFFER/2 + BUTTON_OFFSET );
			spatial.y = BUTTON_BUFFER*1.5;
			
			// close
			//_emotesClose = ButtonCreator.createButtonEntity(clip["button_close"], this, onClose, null, null, null, false);
			
			//_gameButton = ButtonCreator.createButtonEntity(clip["icon_game"], this, onGameMenu, null, null, null, false); // not used for now
			//_emoteButton = ButtonCreator.createButtonEntity(clip["icon_emote"], this, onEmoteMenu, null, null, null, false);
			//_thinkButton = ButtonCreator.createButtonEntity(clip["icon_think"], this, onThinkMenu, null, null, null, false);
			//_sayButton = ButtonCreator.createButtonEntity(clip["icon_say"], this, onSayMenu, null, null, null, false);
			
			_menuIcons = new Vector.<Entity>();
			//_menuIcons.push( _thinkButton );
			//_menuIcons.push( _emoteButton );
			//_menuIcons.push( _sayButton );
			
			// main emote icon menu
			_emoteIcons = new Vector.<Entity>();
			_emoteIcons.push( ButtonCreator.createButtonEntity(clip["icon_laugh"], this, Command.create(onEmote, "Laugh"), null, null, null, false) );
			_emoteIcons.push( ButtonCreator.createButtonEntity(clip["icon_smile"], this, Command.create(onEmote, "Proud"), null, null, null, false) );
			_emoteIcons.push( ButtonCreator.createButtonEntity(clip["icon_cry"], this, Command.create(onEmote, "Cry"), null, null, null, false) );
			// this tired emote doesn't do anything
			//_emoteIcons.push( ButtonCreator.createButtonEntity(clip["icon_tired"], this, Command.create(onEmote, "SitSleepLoop"), null, null, null, false) );
			_emoteIcons.push( ButtonCreator.createButtonEntity(clip["icon_angry"], this, Command.create(onEmote, "Angry"), null, null, null, false) );
			_emoteIcons.push( ButtonCreator.createButtonEntity(clip["icon_crazy"], this, Command.create(onEmote, "RobotDance"), null, null, null, false) );
			
			// say menu
			_sayIcons = new Vector.<Entity>();
			
			// think menu
			_thinkIcons = new Vector.<Entity>();
			/*
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_question"], this, Command.create(onThink, "question"), null, null, null, false) );
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_idea"], this, Command.create(onThink, "idea"), null, null, null, false) );
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_exlamation"], this, Command.create(onThink, "exlamation"), null, null, null, false) );
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_direction_right"], this, Command.create(onThink, "direction_right"), null, null, null, false) );
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_look"], this, Command.create(onThink, "look"), null, null, null, false) );
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_direction_left"], this, Command.create(onThink, "direction_left"), null, null, null, false) );
			_thinkIcons.push( ButtonCreator.createButtonEntity(clip["icon_food"], this, Command.create(onThink, "food"), null, null, null, false) );
			
			thinkIconData["question"] = new BitmapData(clip["icon_question"].width, clip["icon_question"].height, true, 0x00000000);
			BitmapData(thinkIconData["question"]).draw(clip["icon_question"], new Matrix(1,0,0,1, -clip["icon_question"].getBounds(clip["icon_question"]).x, -clip["icon_question"].getBounds(clip["icon_question"]).y));
			
			thinkIconData["idea"] = new BitmapData(clip["icon_idea"].width, clip["icon_idea"].height, true, 0x00000000);
			BitmapData(thinkIconData["idea"]).draw(clip["icon_idea"], new Matrix(1,0,0,1, -clip["icon_idea"].getBounds(clip["icon_idea"]).x, -clip["icon_idea"].getBounds(clip["icon_idea"]).y));
			
			thinkIconData["exlamation"] = new BitmapData(clip["icon_exlamation"].width, clip["icon_exlamation"].height, true, 0x00000000);
			BitmapData(thinkIconData["exlamation"]).draw(clip["icon_exlamation"], new Matrix(1,0,0,1, -clip["icon_exlamation"].getBounds(clip["icon_exlamation"]).x, -clip["icon_exlamation"].getBounds(clip["icon_exlamation"]).y));
			
			thinkIconData["direction_right"] = new BitmapData(clip["icon_direction_right"].width, clip["icon_direction_right"].height, true, 0x00000000);
			BitmapData(thinkIconData["direction_right"]).draw(clip["icon_direction_right"], new Matrix(1,0,0,1, -clip["icon_direction_right"].getBounds(clip["icon_direction_right"]).x, -clip["icon_direction_right"].getBounds(clip["icon_direction_right"]).y));
			
			thinkIconData["look"] = new BitmapData(clip["icon_look"].width, clip["icon_look"].height, true, 0x00000000);
			BitmapData(thinkIconData["look"]).draw(clip["icon_look"], new Matrix(1,0,0,1, -clip["icon_look"].getBounds(clip["icon_look"]).x, -clip["icon_look"].getBounds(clip["icon_look"]).y));
			
			thinkIconData["direction_left"] = new BitmapData(clip["icon_direction_left"].width, clip["icon_direction_left"].height, true, 0x00000000);
			BitmapData(thinkIconData["direction_left"]).draw(clip["icon_direction_left"], new Matrix(1,0,0,1, -clip["icon_direction_left"].getBounds(clip["icon_direction_left"]).x, -clip["icon_direction_left"].getBounds(clip["icon_direction_left"]).y));
			
			thinkIconData["food"] = new BitmapData(clip["icon_food"].width, clip["icon_food"].height, true, 0x00000000);
			BitmapData(thinkIconData["food"]).draw(clip["icon_food"], new Matrix(1,0,0,1, -clip["icon_food"].getBounds(clip["icon_food"]).x, -clip["icon_food"].getBounds(clip["icon_food"]).y));
			*/
			
			// game menu
			_gameIcons = new Vector.<Entity>();
			
			/*
			_gameIcons.push( ButtonCreator.createButtonEntity(clip["icon_starLink"], this, Command.create(onGame, "starLink"), null, null, null, false) );
			_gameIcons.push( ButtonCreator.createButtonEntity(clip["icon_skyDive"], this, Command.create(onGame, "skyDive"), null, null, null, false) );
			
			gameIconData["starLink"] = new BitmapData(clip["icon_starLink"].width, clip["icon_starLink"].height, true, 0x00000000);
			BitmapData(gameIconData["starLink"]).draw(clip["icon_starLink"], new Matrix(1,0,0,1, -clip["icon_starLink"].getBounds(clip["icon_starLink"]).x, -clip["icon_starLink"].getBounds(clip["icon_starLink"]).y));
			
			gameIconData["skyDive"] = new BitmapData(clip["icon_skyDive"].width, clip["icon_skyDive"].height, true, 0x00000000);
			BitmapData(gameIconData["skyDive"]).draw(clip["icon_skyDive"], new Matrix(1,0,0,1, -clip["icon_skyDive"].getBounds(clip["icon_skyDive"]).x, -clip["icon_skyDive"].getBounds(clip["icon_skyDive"]).y));
			*/
			
			// hide icons
			hideGroup(_menuIcons);
			hideGroup(_emoteIcons);
			hideGroup(_thinkIcons);
			hideGroup(_sayIcons);
			hideGroup(_gameIcons);
			
			// hide close button
			//Display(_emotesClose.get(Display)).visible = false;
			
			// hide game button
			// Display(_gameButton.get(Display)).visible = false;
			
		}
		
		private function onHudOpen($open:Boolean):void
		{
			if($open){
				// hide _emotesButton
				Display(_emotesButton.get(Display)).visible = false;
				hideAllEmotes();
			} else {
				Display(_emotesButton.get(Display)).visible = true;
			}
		}
		
		public function showEmotes(state:Boolean):void
		{
			Display(_emotesButton.get(Display)).visible = state;
			
			// set sleep
			Sleep(_emotesButton.get(Sleep)).sleeping = !state;
			
			// toggle tooltip
			if (state)
			{
				_emotesButton.add(new ToolTipActive());
			}
			else
			{
				_emotesButton.remove(ToolTipActive);
			}
			if (!state)
				hideAllEmotes();
		}
		
		protected function onBGClicked( entity:Entity = null ):void 
		{
			this.playCancel();
			hideAllEmotes();
		}
		
		private function onMenu($button:Entity):void{
			
			if(!_emotesShown){
				// arrange icons in radial pattern
				var angleSeg:Number = 360 / _menuIcons.length;
				var start:Number = 0 - (angleSeg/2) - 90;
				var center:Point = new Point(_sfSceneGroup.scene.shellApi.viewportWidth / 2, _sfSceneGroup.scene.shellApi.viewportHeight / 2);
				
				var d:Number = 120;
				
				var startSpatial:Spatial = _emotesButton.get(Spatial);
				//var startSpatial:Spatial = _sfSceneGroup.scene.shellApi.player.get(Spatial);
				
				for(var c:int = 0; c < _menuIcons.length; c++){
					
					var spatial:Spatial = _menuIcons[c].get(Spatial);
					var nX:Number = d * Math.cos(Maths.asRadians(start+(angleSeg*c)));
					var nY:Number = d * Math.sin(Maths.asRadians(start+(angleSeg*c)));
					
					spatial.x = startSpatial.x;
					spatial.y = startSpatial.y;
					
					TweenUtils.entityTo(_menuIcons[c], Spatial, 0.4, {x:center.x + nX, y:center.y + nY}, "", c * 0.05);
					
					Display(_menuIcons[c].get(Display)).visible = true;
					Button(_menuIcons[c].get(Button)).active = true;
					_menuIcons[c].add(new ToolTipActive());
				}
				
				this.playClick();
				
				_emotesShown = true;
			} else {
				
				this.playCancel();
				
				hideAllEmotes();
				
			}
		}
		
		
		private function onEmoteMenu($button:Entity):void
		{
			hideGroup(_menuIcons);
			
			if(!_emotesShown){
				var angleSeg:Number = 360 / _emoteIcons.length;
				var start:Number = 0 - (angleSeg/2) - 90;
				var center:Point = new Point(_sfSceneGroup.scene.shellApi.viewportWidth / 2, _sfSceneGroup.scene.shellApi.viewportHeight / 2);
				
				var d:Number = 150;
				
				var startSpatial:Spatial = _emotesButton.get(Spatial);
				//var startSpatial:Spatial = _emoteButton.get(Spatial);
				
				for(var c:int = 0; c < _emoteIcons.length; c++){
					var spatial:Spatial = _emoteIcons[c].get(Spatial);
					var nX:Number = d * Math.cos(Maths.asRadians(start+(angleSeg*c)));
					var nY:Number = d * Math.sin(Maths.asRadians(start+(angleSeg*c)));
					
					spatial.x = startSpatial.x;
					spatial.y = startSpatial.y;
					spatial.width = startSpatial.width;
					spatial.height = startSpatial.height;
					
					TweenUtils.entityTo(_emoteIcons[c], Spatial, 0.4, {x:center.x + nX, y:center.y + nY, width:startSpatial.width * 1.2, height:startSpatial.height * 1.2}, "", c * 0.05);
					
					Display(_emoteIcons[c].get(Display)).visible = true;
					Button(_emoteIcons[c].get(Button)).active = true;
					_emoteIcons[c].add(new ToolTipActive());
				}
				
				_emotesShown = true;
				EntityUtils.getDisplayObject(_background).visible = true;
			} else {
				this.playCancel();
				
				hideAllEmotes();
			}
		}
		
		
		private function onSayMenu($button:Entity):void{
			hideGroup(_menuIcons);
			
			var angleSeg:Number = 360 / _sayIcons.length;
			var start:Number = 0 - (angleSeg/2) - 90;
			var center:Point = new Point(_sfSceneGroup.scene.shellApi.viewportWidth / 2, _sfSceneGroup.scene.shellApi.viewportHeight / 2);
			
			var d:Number = 100;
			
			var startSpatial:Spatial = _sayButton.get(Spatial);
			
			for(var c:int = 0; c < _sayIcons.length; c++){
				var spatial:Spatial = _sayIcons[c].get(Spatial);
				var nX:Number = d * Math.cos(Maths.asRadians(start+(angleSeg*c)));
				var nY:Number = d * Math.sin(Maths.asRadians(start+(angleSeg*c)));
				
				spatial.x = startSpatial.x;
				spatial.y = startSpatial.y;
				
				TweenUtils.entityTo(_sayIcons[c], Spatial, 0.4, {x:center.x + nX, y:center.y + nY}, "", c * 0.05);
				
				Display(_sayIcons[c].get(Display)).visible = true;
				Button(_sayIcons[c].get(Button)).active = true;
				_sayIcons[c].add(new ToolTipActive());
			}
		}
		
		
		private function onThinkMenu($button:Entity):void{
			hideGroup(_menuIcons);
			
			var angleSeg:Number = 360 / _thinkIcons.length;
			var start:Number = 0 - (angleSeg/2) - 90;
			var center:Point = new Point(_sfSceneGroup.scene.shellApi.viewportWidth / 2, _sfSceneGroup.scene.shellApi.viewportHeight / 2);
			
			var d:Number = 200;
			
			var startSpatial:Spatial = _thinkButton.get(Spatial);
			
			for(var c:int = 0; c < _thinkIcons.length; c++){
				var spatial:Spatial = _thinkIcons[c].get(Spatial);
				var nX:Number = d * Math.cos(Maths.asRadians(start+(angleSeg*c)));
				var nY:Number = d * Math.sin(Maths.asRadians(start+(angleSeg*c)));
				
				spatial.x = startSpatial.x;
				spatial.y = startSpatial.y;
				
				TweenUtils.entityTo(_thinkIcons[c], Spatial, 0.4, {x:center.x + nX, y:center.y + nY}, "", c * 0.05);
				
				Display(_thinkIcons[c].get(Display)).visible = true;
				Button(_thinkIcons[c].get(Button)).active = true;
				_thinkIcons[c].add(new ToolTipActive());
			}
		}
		
		private function onGameMenu($button:Entity):void{
			hideGroup(_menuIcons);
			
			var angleSeg:Number = 360 / _gameIcons.length;
			var start:Number = 0 - (angleSeg/2) - 90;
			var center:Point = new Point(_sfSceneGroup.scene.shellApi.viewportWidth / 2, _sfSceneGroup.scene.shellApi.viewportHeight / 2);
			
			var d:Number = 200;
			
			var startSpatial:Spatial = _gameButton.get(Spatial);
			
			for(var c:int = 0; c < _gameIcons.length; c++){
				var spatial:Spatial = _gameIcons[c].get(Spatial);
				var nX:Number = d * Math.cos(Maths.asRadians(start+(angleSeg*c)));
				var nY:Number = d * Math.sin(Maths.asRadians(start+(angleSeg*c)));
				
				spatial.x = startSpatial.x;
				spatial.y = startSpatial.y;
				
				TweenUtils.entityTo(_gameIcons[c], Spatial, 0.4, {x:center.x + nX, y:center.y + nY}, "", c * 0.05);
				
				Display(_gameIcons[c].get(Display)).visible = true;
				Button(_gameIcons[c].get(Button)).active = true;
				_gameIcons[c].add(new ToolTipActive());
			}
		}
		
		private function onClose($button:Entity):void{
			// hide all icons
			
		}
		
		private function hideGroup($entities:Vector.<Entity>):void{
			for each(var entity:Entity in $entities){
				Display(entity.get(Display)).visible = false;
				Button(entity.get(Button)).active = false;
				entity.remove(ToolTipActive);
			}
		}
		
		private function hideAllEmotes():void{
			hideGroup(_menuIcons);
			hideGroup(_emoteIcons);
			hideGroup(_thinkIcons);
			hideGroup(_sayIcons);
			hideGroup(_gameIcons);
			_emotesShown = false;
			EntityUtils.getDisplayObject(_background).visible = false;
		}
		
		private function onEmote($button:Entity, $type:String):void{
			// check player's state
			var validStates:Array = [CharacterState.STAND, CharacterState.WALK];
			//if(CharUtils.getStateType(shellApi.player) == "stand"){
			if( validEmoteStates.indexOf( CharUtils.getStateType(shellApi.player) ) != -1 ){
				runEmote($type);
			}
			this.playClick();
			hideAllEmotes();
		}
		
		private function onStatement($button:Entity, $msg:String, $ani:String = null):void{
			if($ani != null){
				runEmote($ani);
			}
			runStatement($msg);
			hideAllEmotes();
		}
		
		
		public function onThink($button:Entity, $think:String):void{
			runThink($think);
			hideAllEmotes();
		}
		
		private function onGame($button:Entity, $game:String):void
		{
			runGame($game);
			hideAllEmotes();
		}
		
		public function runStatement($msg:String = "Hello World!"):void{
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_STATEMENT);
			obj.putUtfString(SFSceneGroup.KEY_MSG, $msg);
			
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		public function runEmote($ani:String = "Laugh"):void{
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_EMOTE);
			obj.putUtfString(SFSceneGroup.KEY_MSG, $ani);
			
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		private function runThink($think:String):void{
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_THINK);
			obj.putUtfString(SFSceneGroup.KEY_MSG, $think);
			
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		private function runGame($game:String):void{
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_GAME_ADV);
			obj.putUtfString(SFSceneGroup.KEY_MSG, $game);
			
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		public function onGameIcon($button:Entity, $userId:int, $game:String):void{
			var obj:ISFSObject = new SFSObject();
			obj.putUtfString(SFSceneGroup.KEY_ACTION_TYPE, SFSceneGroup.TYPE_PLAYER_GAME_INV);
			obj.putInt(SFSceneGroup.KEY_TARGET_USER_ID, $userId);
			obj.putUtfString(SFSceneGroup.KEY_MSG, $game);
			
			shellApi.smartFox.send(new ExtensionRequest(SFSceneGroup.CMD_PLAYERACTION, _sfSceneGroup.stampObj(obj), shellApi.smartFox.lastJoinedRoom));
		}
		
		public function getButton():Entity { return _emotesButton; }

		
		private var _sfSceneGroup:SFSceneGroup;
		
		private var _menuIcons:Vector.<Entity>;
		private var _emoteIcons:Vector.<Entity>;
		private var _sayIcons:Vector.<Entity>;
		private var _thinkIcons:Vector.<Entity>;
		private var _gameIcons:Vector.<Entity>;
		
		public var thinkIconData:Dictionary = new Dictionary();
		public var gameIconData:Dictionary = new Dictionary();
		
		private var _shownIcons:Vector.<Entity> = new Vector.<Entity>();
		private var _emotesButton:Entity;
		private var _emotesClose:Entity;
		
		private var _emotesShown:Boolean = false;
		private var _sayButton:Entity;
		private var _gameButton:Entity;
		private var _thinkButton:Entity;
		private var _emoteButton:Entity;
		private var _background:Entity;
		
		private var _hud:Hud;
		
		protected var _backgroundTint:BitmapWrapper;

	}
}