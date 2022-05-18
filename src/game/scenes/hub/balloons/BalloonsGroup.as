package game.scenes.hub.balloons
{
	import com.smartfoxserver.v2.core.SFSEvent;
	import com.smartfoxserver.v2.entities.data.ISFSArray;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.data.SFSObject;
	import com.smartfoxserver.v2.requests.ExtensionRequest;
	
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.scenes.hub.balloons.components.BalloonCell;
	import game.scenes.hub.balloons.components.BalloonsGrid;
	import game.scenes.hub.skydive.SmartFoxGroup;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class BalloonsGroup extends Group
	{
		public static const GROUP_ID:String 				= "balloonsGroup";
		public static const CMD_FILL_BALLOON:String 		= "FB";
		
		public static const KEY_BALLOON_COL:String			= "B_C";
		public static const KEY_BALLOON_ROW:String			= "B_R";
		public static const KEY_PLAYER_ID:String			= "PID";
		public static const KEY_GRID_CELL:String			= "C";
		public static const KEY_WON_CELLS:String            = "WC";
		public static const WHOS_TURN:String				= "T";
		
		private var prefix:String;
		
		public function BalloonsGroup(prefix:String = "scenes/hub/balloons/")
		{
			this.prefix = prefix;
			super.id = GROUP_ID;
		}
		
		public function setupGroup(parent:Balloons, smartFoxGroup:SmartFoxGroup):void
		{
			_balloonsGame = parent;
			parent.addChildGroup(this);
			_smartFoxGroup = smartFoxGroup;
			_smartFoxGroup.extensionResponse.add(onSFSExtension);
		}
		
		protected function onSFSExtension($event:SFSEvent):void
		{
			switch($event.params.cmd){
				case CMD_FILL_BALLOON :
					var isfso:ISFSObject = $event.params.params;
					createBalloon(isfso);
					if(isfso.containsKey(KEY_WON_CELLS))
						SceneUtil.addTimedEvent(this, new TimedEvent(3, 1, Command.create(checkWin, $event.params.params)));
					break;
			}
		}
		
		public function playerTurn($playerId:int):void
		{
			_whosTurn = $playerId;
			_balloonsGame.playerTurn($playerId);
		}
		
		public function fillBalloon(column:int):void
		{
			// send fill balloon request to server
			var obj:ISFSObject = new SFSObject();
			obj.putInt(KEY_BALLOON_COL, column);
			_smartFoxGroup.smartFox.send(new ExtensionRequest(CMD_FILL_BALLOON, obj, super.shellApi.smartFox.lastJoinedRoom));
			
			// prevent overlap - by setting _whosTurn to 0
			_whosTurn = 0;
		}
		
		private function createBalloon($isfso:ISFSObject):void
		{
			if($isfso.containsKey(KEY_GRID_CELL)){
				// mark grid cell
				var playerId:int = $isfso.getSFSObject(KEY_GRID_CELL).getInt(KEY_PLAYER_ID);
				var column:int = $isfso.getSFSObject(KEY_GRID_CELL).getInt(KEY_BALLOON_COL);
				var row:int = $isfso.getSFSObject(KEY_GRID_CELL).getInt(KEY_BALLOON_ROW);
				
				var grid:Entity = parent.getEntityById(Balloons.GRID_ID);
				var balloonsGrid:BalloonsGrid = grid.get(BalloonsGrid);
				var balloonCell:BalloonCell = balloonsGrid.data[ column - 1 ][ row - 1 ];
				balloonCell.playerId = playerId;
				
				var balloonCreator:BalloonCreator = new BalloonCreator(prefix);
				_balloons.push(balloonCreator.createBalloon(playerId, column, row, this));
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH+"air_pump_release_01.mp3");
				
				if($isfso.containsKey(WHOS_TURN))
					playerTurn($isfso.getInt(WHOS_TURN));
			}
		}
		
		public function checkWin($isfso:ISFSObject):void
		{
			if($isfso.containsKey(KEY_WON_CELLS)){
				// turn winning balloons gold
				var wonCells:ISFSArray = $isfso.getSFSArray(KEY_WON_CELLS);
				var popBalloons:Vector.<Entity> = new Vector.<Entity>();
				var balloon:Entity;
				for each(balloon in _balloons){
					popBalloons.push(balloon);
				}
				
				for(var c:int = 0; c < wonCells.size(); c++){
					var cell:ISFSObject = wonCells.getSFSObject(c);
					balloon = balloonAt(cell.getInt(KEY_BALLOON_COL), cell.getInt(KEY_BALLOON_ROW));
					var balloonChild:Entity = TimelineUtils.getChildClip(balloon, "content");
					var gold:Entity = TimelineUtils.getChildClip(balloonChild, "gold");
					Timeline(gold.get(Timeline)).play();
					
					removeBalloonFromVector(balloon, popBalloons);
				}
				
				popThemBalloons(popBalloons); // pop remaining balloons
			}
		}
		
		private function removeBalloonFromVector($balloon:Entity, $vector:Vector.<Entity>):void
		{
			for(var c:int = 0; c < $vector.length; c++){
				if($balloon == $vector[c]){
					$vector.splice(c,1);
				}
			}
		}
		
		private function popThemBalloons($balloons:Vector.<Entity>):void
		{
			for(var c:int = 0; c < $balloons.length; c++){
				var balloon:Entity = $balloons[c];
				SceneUtil.addTimedEvent(this, new TimedEvent(c*0.1, 1, Command.create(popBalloon, balloon)));
			}
			SceneUtil.addTimedEvent(this, new TimedEvent($balloons.length*0.1 + 0.5, 1, Balloons(this.parent).popLastBalloon));
		}
		
		private function popBalloon($balloon:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH+"balloon_pop_01.mp3", 0.7);
			var balloonChild:Entity = TimelineUtils.getChildClip($balloon, "content");
			Timeline(balloonChild.get(Timeline)).play();
		}
		
		public function getPumpPoint(column:int):Point
		{
			var point:Point;
			var pump:Entity = parent.getEntityById("pump"+column);
			var spatial:Spatial = pump.get(Spatial);
			
			point = DisplayUtils.localToLocalPoint(new Point(spatial.x, spatial.y), Display(parent.getEntityById(Balloons.PUMPS_ID).get(Display)).displayObject, Balloons(parent).hitContainer);
			
			return point;
		}
		
		public function getGridPoint(column:int, row:int):Point
		{
			var point:Point;
			var grid:Entity = parent.getEntityById(Balloons.GRID_ID);
			var balloonsGrid:BalloonsGrid = grid.get(BalloonsGrid);
			
			var balloonCell:BalloonCell = balloonsGrid.data[ column - 1 ][ row - 1 ];
			
			return balloonCell.coords;
		}
		
		public function balloonAt(column:int, row:int):Entity
		{
			return parent.getEntityById("balloon_"+column+"_"+row);
		}
		
		public function columnAvailable(column:int):Boolean
		{
			var grid:Entity = parent.getEntityById(Balloons.GRID_ID);
			var balloonsGrid:BalloonsGrid = grid.get(BalloonsGrid);
			
			for(var r:int = 1; r <= BalloonsGrid.ROW_NUM; r++){
				var balloonCell:BalloonCell = balloonsGrid.data[ column - 1 ][ r - 1 ];
				if(balloonCell.playerId == 0){
					return true;
				}
			}
			
			
			return false;
		}
		
		public function endGame():void
		{
			// clear cells
			var grid:Entity = parent.getEntityById(Balloons.GRID_ID);
			var balloonsGrid:BalloonsGrid = grid.get(BalloonsGrid);
			for(var c:int = 1; c <= BalloonsGrid.COLUMN_NUM; c++){
				for(var r:int = 1; r <= BalloonsGrid.ROW_NUM; r++){
					var balloonCell:BalloonCell = balloonsGrid.data[ c - 1 ][ r - 1 ];
					balloonCell.playerId = 0;
				}
			}
			
			// clear balloons
			for each(var balloon:Entity in _balloons)
			{
				balloon.group.removeEntity(balloon);
			}
			_balloons = new Vector.<Entity>();
			
			// reset 
			_whosTurn = 0;
		}
		
		public function get whosTurn():int{ return _whosTurn };
		
		private var _balloonsGame:Balloons;
		private var _balloons:Vector.<Entity> = new Vector.<Entity>();
		private var _smartFoxGroup:SmartFoxGroup;
		private var _whosTurn:int;
	}
}