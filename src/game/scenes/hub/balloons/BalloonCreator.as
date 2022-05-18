package game.scenes.hub.balloons
{
	import com.greensock.easing.Cubic;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.timeline.Timeline;
	import game.data.WaveMotionData;
	import game.scene.template.GameScene;
	import game.scenes.hub.balloons.components.Balloon;
	import game.util.BitmapUtils;
	import game.util.DisplayUtils;
	import game.util.MotionUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;

	public class BalloonCreator
	{
		public static const RED_COLOR:int 						= 1;
		public static const BLUE_COLOR:int 						= 2;
		
		private var prefix:String;
		
		public function BalloonCreator(prefix:String = "scenes/hub/balloons/")
		{
			this.prefix = prefix;
		}
		
		public function createBalloon(color:int, column:int, row:int, group:Group):Entity{

			var balloon:Entity = new Entity();
			balloon.add(new Balloon(column, row));
			balloon.add(new Motion());
			balloon.add(new Id("balloon_"+column+"_"+row));
			
			var pumps:Entity = group.getEntityById(Balloons.PUMPS_ID);
			var point:Point = BalloonsGroup(group).getPumpPoint(column);
			
			balloon.add(new Spatial(point.x, point.y));
			group.parent.addEntity(balloon);
			
			switch(color){
				case RED_COLOR:
					group.shellApi.loadFile(group.shellApi.assetPrefix + prefix + "balloonRed.swf", Command.create(fillBalloon, balloon));
					break;
				case BLUE_COLOR:
					group.shellApi.loadFile(group.shellApi.assetPrefix + prefix + "balloonBlue.swf", Command.create(fillBalloon, balloon));
					break;
			}
			
			return balloon;
		}
		
		private function fillBalloon(clip:MovieClip, balloon:Entity):void{
			
			balloon.add(new Display(clip));
			TimelineUtils.convertAllClips(clip, balloon);
			BitmapUtils.convertContainer(clip);
			
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			//animate fill
			var spatial:Spatial = balloon.get(Spatial);
			var origY:Number = spatial.y;
			var origH:Number = spatial.height;
			
			spatial.scaleX = 0.1;
			spatial.scaleY = 0.1;
			TweenUtils.entityTo(balloon, Spatial, 1, {scaleX:1, scaleY:1, y:origY-(origH/2), onStart:addBalloon, onStartParams:[clip, balloon], onComplete:launchBalloon, onCompleteParams:[balloon]});
		}
		
		private function addBalloon(clip:MovieClip, balloon:Entity):void{
			GameScene(balloon.group).hitContainer.addChild(clip);
			
			// move text above the balloons
			var launchTxt:Entity = balloon.group.getEntityById(Balloons.TXT_LAUNCH_ID);
			var waitTxt:Entity = balloon.group.getEntityById(Balloons.TXT_WAIT_ID);
			DisplayUtils.moveToTop(Display(launchTxt.get(Display)).displayObject);
			DisplayUtils.moveToTop(Display(waitTxt.get(Display)).displayObject);
			
		}
		
		private function launchBalloon(balloonEntity:Entity):void{

			var content:Entity = TimelineUtils.getChildClip(balloonEntity, "content");
			Timeline(content.get(Timeline)).gotoAndStop(1);
			
			MotionUtils.addWaveMotion(balloonEntity, new WaveMotionData("y", 8, 0.04, "sin", 1));
			MotionUtils.addWaveMotion(balloonEntity, new WaveMotionData("x", 4, 0.016, "sin", 1));
			
			// calculate destintion by the balloon component
			var balloon:Balloon = balloonEntity.get(Balloon);
			var dPoint:Point = BalloonsGroup(balloonEntity.group.getGroupById(BalloonsGroup.GROUP_ID)).getGridPoint(balloon.column, balloon.row);
			
			TweenUtils.entityTo(balloonEntity, Spatial, 2, {x:dPoint.x, y:dPoint.y, ease:Cubic.easeInOut});
		}

	}
}