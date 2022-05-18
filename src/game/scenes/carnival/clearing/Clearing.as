package game.scenes.carnival.clearing{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import fl.transitions.easing.None;
	
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Sit;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Clearing extends PlatformerGameScene
	{
		private var _monsters:Vector.<Entity>;
		private var _charIDs:Array = ["tunnelLove","duckGame","ralph","foodStand","ferrisWheel","testStrength","weightGuesser","macchio"];
		private var _monsterSwfs:Array = ["tunnelLoveTrans.swf","duckGameTrans.swf","ralphTrans.swf","foodStandTrans.swf","ferrisWheelTrans.swf","stengthTestTrans.swf","weightGuesserTrans.swf","macchioTrans.swf"];

		private var _events:CarnivalEvents;
		
		private var cameraDummy:Entity;
		private var nightFallsTL:Entity;
		
		public function Clearing()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/clearing/";
			
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
			addSystem(new ThresholdSystem());
			_monsters = new Vector.<Entity>();
			_events = events as CarnivalEvents;
			cameraDummy = new Entity();
			cameraDummy.add(new Spatial(0,0));
			addEntity(cameraDummy);
			loadMonsters();
			loadDuskScene();
			shellApi.triggerEvent(_events.SET_NIGHT, true);
			shellApi.removeEvent(_events.SET_DAY);
			shellApi.removeEvent(_events.SET_MORNING);
			shellApi.removeEvent(_events.SET_EVENING);
			super.loaded();
		}
		
		private function loadDuskScene():void
		{
			loadFile("dusktoNight.swf",duskLoaded);
		}
		
		private function duskLoaded(clip:MovieClip):void
		{
			overlayContainer.addChild(clip);
			nightFallsTL = TimelineUtils.convertClip(clip,this,null,null,false);
		}		
		
		
		private function loadMonsters():void
		{
			getEntityById("ralphMonsterForm").get(Display).visible = false;
			getEntityById("macchioMonsterForm").get(Display).visible = false;
			loadFiles(_monsterSwfs,false,true,allMonstersLoaded);
		}
		
		private function allMonstersLoaded():void
		{
			for (var i:int = 0; i < _monsterSwfs.length; i++) 
			{
				var clip:MovieClip = getAsset(_monsterSwfs[i]) as MovieClip;
				var monster:Entity = EntityUtils.createSpatialEntity(this, clip, hitContainer);
				monster = TimelineUtils.convertClip(clip,this,monster,null,false);
				monster.add(new Id(_charIDs[i]+"monster"));
				_monsters.push(monster);
			}
			SceneUtil.lockInput( this );
			movePlayer("nav0",reachedBush);
		}
		
		// move to bush and crouch
		private function movePlayer(nav:String, complete:Function):void
		{
			var clip:MovieClip = _hitContainer[nav] as MovieClip;
			CharUtils.moveToTarget(player,clip.x,clip.y,true,complete, new Point( 50, 100 ) );
		}
		
		private function reachedBush(player:Entity):void
		{
			CharUtils.setAnim(player,Sit);
			player.get(Dialog).sayById("seeCarnies");
			player.get(Dialog).complete.addOnce(startMonsters);
		}
		
		private function startMonsters(...p):void
		{
			var end:Point = EntityUtils.getPosition(getEntityById(_charIDs[0]));
			EntityUtils.positionByEntity(cameraDummy,player);
			SceneUtil.setCameraTarget(this,cameraDummy);
			TweenUtils.globalTo(this,cameraDummy.get(Spatial),2,{x:end.x, y:end.y,ease:None.easeNone, onComplete:showShadow},"cam",1);
		}
		
		private function showShadow():void
		{
			var end:Point = EntityUtils.getPosition(getEntityById("shadow"));
			EntityUtils.positionByEntity(cameraDummy,getEntityById(_charIDs[0]));
			SceneUtil.setCameraTarget(this,cameraDummy);
			TweenUtils.globalTo(this,cameraDummy.get(Spatial),2,{x:end.x, y:end.y,ease:None.easeNone, onComplete:speak},"cam",1);
		}
		
		private function speak():void
		{
			var shadow:Entity = getEntityById("shadow");
			shadow.get(Dialog).sayById("speech");
			shadow.get(Dialog).complete.addOnce(poseShadow);
		}
		
		private function poseShadow(...p):void
		{
			var shadow:Entity = getEntityById("shadow");
			CharUtils.setAnim(shadow,Grief);
			CharUtils.getTimeline(shadow).handleLabel("end", startMorphing)
			shellApi.triggerEvent("monsters_emerge");
		}
		
		private function startMorphing(...p):void
		{
			showNextMonster();
		}
		
		private function showNextMonster(index:int=0):void
		{
			var char:Entity = getEntityById(_charIDs[index]);
			if(index < _monsters.length){
				var monster:Entity = _monsters[index];
				monster.get(Display).moveToBack();
				EntityUtils.positionByEntity(monster,char);
				SceneUtil.setCameraTarget(this, monster);
				TweenUtils.globalTo(this,char.get(Display),1,{alpha:0},"char"+index);
				TweenUtils.globalFrom(this,monster.get(Display),1.1,{alpha:0},"monster"+index);
				var tl:Timeline = monster.get(Timeline);
				tl.gotoAndPlay("start");
				tl.handleLabel("end",Command.create(delayNext, index));
				tl.handleLabel("show",Command.create(loadGremlins, index));
				//sound
				shellApi.triggerEvent("morphSound"+index);
			}
			else{
				//pan across scene back to player
				EntityUtils.positionByEntity(cameraDummy, _monsters[0]);
				var end:Point = EntityUtils.getPosition(player);
				SceneUtil.setCameraTarget(this,cameraDummy);
				var talk:Function = Command.create(player.get(Dialog).sayById,"seeCarnieMonsters");
				TweenUtils.globalTo(this,cameraDummy.get(Spatial),3,{x:end.x, y:end.y,ease:None.easeNone, onComplete:talk},"cam",1);
				player.get(Dialog).complete.addOnce(leaveScene);
			}
		}
		
		private function loadGremlins(index:int=0):void
		{
			//show ralph/macchio monster forms
			if(_charIDs[index] == "ralph"){
				_monsters[index].get(Display).moveToFront();
				getEntityById("ralphMonsterForm").get(Display).visible = true;
			}
			else if(_charIDs[index] == "macchio"){
				getEntityById("macchioMonsterForm").get(Display).visible = true;
			}
		}		
		
		
		private function delayNext(index:int=0):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1.2,1,Command.create(showNextMonster,index+1)));
		}
		
		private function leaveScene(...p):void
		{
			movePlayer("nav1",doDuskSeq);
		}
		
		private function doDuskSeq(...p):void
		{
			shellApi.triggerEvent(_events.MONSTERS_UNLEASHED,true);
			var tl:Timeline = nightFallsTL.get(Timeline);
			tl.play();
			tl.handleLabel("end",useDoor);
		}
		
		private function useDoor(...p):void
		{
			var door:Entity = getEntityById("doorWoodsMaze");
			door.get(Door).open = true;
		}
		
	}
}




