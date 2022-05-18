package game.scenes.hub.starLink
{
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.data.ISFSArray;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.creators.ui.ButtonCreator;
	import game.scenes.hub.skydive.SmartFoxGroup;
	import game.scenes.hub.starLink.components.StarLinkBox;
	import game.scenes.hub.starLink.components.StarLinkLine;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class StarLinkGroup extends Group
	{
		
		public function StarLinkGroup(scene:StarLink, container:DisplayObjectContainer, smartFoxGroup:SmartFoxGroup)
		{
			_scene = scene;
			_container = container;
			_smartFoxGroup = smartFoxGroup;
		}
		
		override public function added():void
		{
			setupLines();
			setupBoxes();
			setupSmartFox();
			
			MovieClip(_container["stars"]).mouseEnabled = false;
			MovieClip(_container["stars"]).mouseChildren = false;
		}
		
		private function setupSmartFox():void
		{
			_smartFoxGroup.extensionResponse.add(onSFSExtension);
		}
		
		protected function onSFSExtension($event:SFSEvent):void
		{
			switch($event.params.cmd)
			{
				case "markLine" :
					parseMarkObject($event.params.params);
					break;
			}
		}
		
		private function parseMarkObject($sfsObject:ISFSObject):void
		{
			var lineSFS:ISFSObject = $sfsObject.getSFSObject("line");
			
			if(lineSFS)
			{
				var lineEntity:Entity = _linesDict[lineSFS.getUtfString("id")];
				Timeline(lineEntity.get(Timeline)).gotoAndStop(lineSFS.getInt("playerId")+2);
				StarLinkLine(lineEntity.get(StarLinkLine)).playerId = lineSFS.getInt("playerId");
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"retro_ping_05.mp3");
			} else {
				
				throw new Error("No line object recieved in mark Extension!");
				return;
				
			}
			
			var boxesSFS:ISFSArray = $sfsObject.getSFSArray("boxes");
			
			if(boxesSFS)
			{
				for(var c:int = 0; c < boxesSFS.size(); c++)
				{
					var boxSFS:ISFSObject = boxesSFS.getSFSObject(c);
					var boxEntity:Entity = _boxesDict[boxSFS.getUtfString("id")];
					
					Timeline(boxEntity.get(Timeline)).gotoAndStop(boxSFS.getInt("playerId"));
					StarLinkBox(boxEntity.get(StarLinkBox)).playerId = boxSFS.getInt("playerId");
					
					_scene.score(boxSFS.getInt("playerId"));
				}
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"achievement_02.mp3");
				
			}
			
			playerTurn($sfsObject.getInt("whosTurn"));
		}
		
		public function playerTurn($playerId:int):void
		{
			_scene.playerTurn($playerId);
			if(shellApi.smartFox.mySelf.playerId == $playerId){
				startTurn();
			}
			
			_whosTurn = $playerId;
		}
		
		private function setupLines():void
		{
			// create lines
			for(var cc:int = ("a").charCodeAt(0); cc <= ("a").charCodeAt(0) + ROW_NUM; cc++){
				for(var c:int = 1; c <= COL_NUM + 1; c++){
					createStarLine(_container["line_"+String.fromCharCode(cc)+c+"h"]);
					createStarLine(_container["line_"+String.fromCharCode(cc)+c+"v"]);
				}
			}
			
			// disable by default
			disableLines();
		}

		
		private function createStarLine($lineClip:MovieClip):Entity
		{
			if($lineClip){
				
				//var line:Entity = ButtonCreator.createButtonEntity($lineClip, this, onLineClick, _container);
				
				var line:Entity = EntityUtils.createSpatialEntity(this, $lineClip, _container);
				TimelineUtils.convertClip($lineClip, this, line, null, false);
				line.add(new Id($lineClip.name));
				line.add(new StarLinkLine());
				
				ButtonCreator.assignButtonEntity(line, $lineClip as DisplayObjectContainer, this, onLineClick, _container, [InteractionCreator.CLICK, InteractionCreator.OVER, InteractionCreator.OUT], null, true, true);
				
				var interaction:Interaction = line.get(Interaction);
				interaction.click.add(onLineClick);
				interaction.over.add(onLineOver);
				interaction.out.add(onLineOut);
				
				_lines.push(line);
				
				_linesDict[$lineClip.name.slice(5)] = line;
				
				return line;
			} else {
				return null;
			}
		}
		
		private function setupBoxes():void
		{
			for(var cc:int = ("a").charCodeAt(0); cc < ("a").charCodeAt(0) + ROW_NUM; cc++){
				for(var c:int = 1; c <= COL_NUM; c++){
					createStarBox(_container["box_"+String.fromCharCode(cc)+c]);
				}
			}
		}
		
		private function createStarBox($boxClip:DisplayObject):Entity
		{
			var box:Entity = EntityUtils.createSpatialEntity(this, $boxClip, _container);
			TimelineUtils.convertClip($boxClip as MovieClip, this, box, null, false);
			box.add(new Id($boxClip.name));
			box.add(new StarLinkBox());
			
			_boxes.push(box);
			
			_boxesDict[$boxClip.name.slice(4)] = box;
			
			return box;
		}
		
		public function startTurn():void
		{
			// activate interactions of board for use
			enableLines();
		}
		
		public function endTurn():void
		{
			// disable board -- show cycling arrow
			disableLines();
		}
		
		public function endGame():void
		{
			_container.visible = false;
			_container.mouseEnabled = false;
			_container.mouseChildren = false;
			
			// disable board
			disableLines();
			
			// reset board
			reset();
		}
		
		public function reset():void
		{
			for each(var line:Entity in _lines){
				StarLinkLine(line.get(StarLinkLine)).playerId = 0;
				Timeline(line.get(Timeline)).gotoAndStop(0);
			}
			
			for each(var box:Entity in _boxes){
				StarLinkBox(box.get(StarLinkBox)).playerId = 0;
				Timeline(box.get(Timeline)).gotoAndStop(0);
			}
			
			_whosTurn = 0;
		}
		
		private function disableLines():void
		{
			// shuts off interactions of all lines
			for each(var line:Entity in _lines){
				Interaction(line.get(Interaction)).lock = true;
				
				// remove left over highlights if any
//				if(StarLinkLine(line.get(StarLinkLine)).playerId == 0){
//					Timeline(line.get(Timeline)).gotoAndStop(0);
//				}
			}
		}
		
		private function enableLines():void
		{
			// turns on available lines' interactions
			for each(var line:Entity in _lines){
				if(StarLinkLine(line.get(StarLinkLine)).playerId == 0){ // if not already played by a player
					Interaction(line.get(Interaction)).lock = false;
				}
			}
		}
		
		private function onLineClick($line:Entity):void
		{
			if(_whosTurn == shellApi.smartFox.mySelf.playerId){
				var sfsObject:ISFSObject = new SFSObject();
				sfsObject.putUtfString("lineId", Id($line.get(Id)).id.slice(5));
				
				if(shellApi.smartFoxManager.isInRoom){
					_smartFoxGroup.smartFox.send(new ExtensionRequest("markLine", sfsObject, shellApi.smartFox.lastJoinedRoom));
					endTurn();
				}
			}
		}
		
		private function onLineOver($line:Entity):void
		{
			Timeline($line.get(Timeline)).gotoAndStop(shellApi.smartFox.mySelf.playerId);
			_lastOver = $line;
		}
		
		private function onLineOut($line:Entity):void
		{
			Timeline($line.get(Timeline)).gotoAndStop(0);
		}
		
		private const ROW_NUM:uint = 3;
		private const COL_NUM:uint = 4;
		
		private var _lines:Vector.<Entity> = new Vector.<Entity>();
		private var _boxes:Vector.<Entity> = new Vector.<Entity>();
		
		private var _lastOver:Entity;
		
		private var _linesDict:Dictionary = new Dictionary();
		private var _boxesDict:Dictionary = new Dictionary();
		
		public function get container():DisplayObjectContainer{ return _container };
		
		private var _scene:StarLink;
		private var _container:DisplayObjectContainer;
		private var _smartFoxGroup:SmartFoxGroup;
		
		private var _whosTurn:int = 0;
		private var _exitButton:Entity;
	}
}