package game.scenes.cavern1.underSurvey
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.PointPistol;
	import game.data.comm.PopResponse;
	import game.scenes.cavern1.shared.Cavern1Scene;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.MoveAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.TimelineAction;
	import game.systems.actionChain.actions.TweenEntityAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class UnderSurvey extends Cavern1Scene
	{
		public function UnderSurvey()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/cavern1/underSurvey/";
			
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
			
			setupDrill();
		}
		
		private function setupDrill():void
		{
			_accel = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["accelerometer"], true, true, null, PerformanceUtils.defaultBitmapQuality + 5.);
			addEntity(_accel);
			
			_drill = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["drill"], true, true, null, PerformanceUtils.defaultBitmapQuality + .5);
			addEntity(_drill);
			_drill.get(Timeline).gotoAndStop("off");
			
			if(!shellApi.checkHasItem(cavern1.MEDAL_CAVERN1))
			{
				InteractionCreator.addToEntity(_accel, [InteractionCreator.CLICK]);
				ToolTipCreator.addToEntity(_accel);
				
				var sceneInt:SceneInteraction = new SceneInteraction();
				sceneInt.reached.addOnce(drillEnding);
				sceneInt.offsetY = 60;
				sceneInt.offsetX = -80;
				sceneInt.minTargetDelta = new Point(30, 80);
				sceneInt.faceDirection = CharUtils.DIRECTION_RIGHT;
				_accel.add(sceneInt);
			}
			else
			{
				removeEntity(_drill);
			}
		}
		
		private function drillEnding(...args):void
		{
			var actionChain:ActionChain = new ActionChain(this);
			actionChain.lockInput = true;
			actionChain.addAction(new TalkAction(player, "saw_drill"));
			actionChain.addAction(new AnimationAction(player, PointPistol));
			actionChain.addAction(new TimelineAction(_accel, "start", "redLoop", false));
			actionChain.addAction(new WaitAction(2));
			actionChain.addAction(new MoveAction(player, new Point(829, 800), new Point(40, 100), 3000));
			actionChain.addAction(new TalkAction(player, "not_stable"));
			actionChain.addAction(new TimelineAction(_drill, "fallStart", "fall", false));
			actionChain.addAction(new TweenEntityAction(_drill, Spatial, 4, {y: 3000})).noWait = true;
			actionChain.addAction(new AnimationAction(player, Fall)).noWait = true;
			actionChain.addAction(new TweenEntityAction(player, Spatial, 4, {y:2800})).noWait = true;
			actionChain.addAction(new WaitAction(2));
			actionChain.addAction(new CallFunctionAction(showVictoryPopup));
			actionChain.execute();
		}
		
		private function showVictoryPopup():void
		{
			shellApi.getItem(cavern1.MEDAL_CAVERN1);
			shellApi.completedIsland(shellApi.island, onCompletions);
		}
		
		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false);
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}
		
		private var _drill:Entity;
		private var _accel:Entity;
	}
}