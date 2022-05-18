package game.scenes.carnival.hauntedLab.systems
{
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Grief;
	import game.data.sound.SoundModifier;
	import game.scenes.carnival.hauntedLab.nodes.PuppetMonsterNode;
	import game.systems.GameSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SkinUtils;

	public class PuppetMonsterSystem extends GameSystem
	{
		private var legAcceleration:Number = 0;
		private var legVelocity:Number = 0;
		private var legDamp:Number = 0.9;
		private var legPush:Number = 0;
		private var flashing:Boolean = false;
		private var maxAccel:Number = 1200;
		private var waveTime:Number = 0;
		private var flashDistance:Number = 150;
		private var entering:Boolean = false;
		private var leaving:Boolean = true;
		private var arrivedAtCage:Boolean = true;
		private var currentCage:Entity;
		private var currentExitCage:Entity;
		private var monsterWait:Number = 0;
		private var scareDelay:Number = 0;
		
		public function PuppetMonsterSystem()
		{
			super(PuppetMonsterNode, updateNode);
		}
		
		private function updateNode( node:PuppetMonsterNode, time:Number ):void
		{
			var itemString:String = SkinUtils.getSkinPart(super.group.shellApi.player, SkinUtils.ITEM).value;
			
			if (currentCage  && (arrivedAtCage || (!leaving && !entering))) {
				monsterWait += time;
				//trace(monsterWait);
				if (monsterWait > 5 && !flashing) {
					monsterWait = 0;
					if (leaving) {
						leaving = false;
						entering = true;
						node.timeline.gotoAndPlay("enter");
						Timeline(currentCage.get(Timeline)).gotoAndPlay("open");
						//super.group.shellApi.triggerEvent("cageDoorSound");
						super.group.shellApi.triggerEvent("monsterEmergeSound");
						node.audio.play(SoundManager.AMBIENT_PATH + "eerie_moaning.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
						//monsterAudio.play(SoundManager.AMBIENT_PATH + "eerie_moaning.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS]);
					}
					else if (!entering) {
						leaving = true;
						arrivedAtCage = false;
						currentExitCage = currentCage;
					}
				}
			}
			
			var clip:MovieClip = node.display.displayObject as MovieClip;
			
			var playerPoint:Point = new Point(super.group.shellApi.player.get(Spatial).x, super.group.shellApi.player.get(Spatial).y);
			node.puppetMonster.target.x = playerPoint.x;
			node.puppetMonster.target.y = playerPoint.y;
			
			var mousePoint:Point = new Point(node.display.displayObject.parent.mouseX, node.display.displayObject.parent.mouseY + 100);
			var monsterPoint:Point = new Point(node.spatial.x, node.spatial.y);
			var distance:Number = Point.distance(mousePoint, monsterPoint);
			
			//check if scared
			scareDelay += time;
			if (scareDelay > 3) {
				var scareDistance:Number = Point.distance(playerPoint, monsterPoint);
				if (!flashing && !entering && !leaving && scareDistance < 150) {
					scareDelay = 0;
					CharUtils.setAnim(super.group.shellApi.player, Grief);
					MotionUtils.zeroMotion(super.group.shellApi.player, "x");
				}
			}
			
			//check if flashing
			if (!entering && !leaving) {
				if (distance < flashDistance && ( itemString == "mc_flashlight_normal" || itemString == "mc_flashlight_black" )) {
					if (!flashing) {
						flashing = true;
						node.timeline.gotoAndPlay("flashStart");
					}
				}
				else {
					if (flashing) {
						flashing = false;
						//clip.gotoAndPlay("floatStart");
						node.timeline.gotoAndPlay("floatStart");
					}
				}
			}
			
			//decide state of monster
			if (entering && currentCage) {
				MotionUtils.zeroMotion(node.entity);
				node.spatial.x = currentCage.get(Spatial).x;
				node.spatial.y = currentCage.get(Spatial).y;
			}
			else if (leaving && currentCage) {
				var cagePoint:Point = new Point(currentExitCage.get(Spatial).x, currentExitCage.get(Spatial).y);
				var cageDistance:Number = Point.distance(monsterPoint, cagePoint);
				node.motion.acceleration.x = (cagePoint.x - node.spatial.x)*6;
				node.motion.acceleration.y = (cagePoint.y - node.spatial.y)*6;
				if (cageDistance < 50) {
					node.spatial.x += (cagePoint.x - node.spatial.x)/2;
					node.spatial.y += (cagePoint.y - node.spatial.y)/2;
					if (!arrivedAtCage) {
						arrivedAtCage = true;
						node.timeline.gotoAndPlay("leave");
						Timeline(currentExitCage.get(Timeline)).gotoAndPlay("open");
						super.group.shellApi.triggerEvent("cageDoorSound");
						node.audio.stop(SoundManager.AMBIENT_PATH + "eerie_moaning.mp3");
					}
				}
			}
			else if (flashing || entering || leaving) {
				//node.motion.acceleration.x = 0;
				//node.motion.acceleration.y = 0;
				MotionUtils.zeroMotion(node.entity);
			}
			else {
				node.motion.acceleration.x = (node.puppetMonster.target.x - node.spatial.x)*4;
				node.motion.acceleration.y = (node.puppetMonster.target.y - node.spatial.y)*4;
			}
			
			if (node.motion.acceleration.x > maxAccel) {
				node.motion.acceleration.x = maxAccel;
			}
			else if (node.motion.acceleration.x < -maxAccel) {
				node.motion.acceleration.x = -maxAccel;
			}
			if (node.motion.acceleration.y > maxAccel) {
				node.motion.acceleration.y = maxAccel;
			}
			else if (node.motion.acceleration.y < -maxAccel) {
				node.motion.acceleration.y = -maxAccel;
			}
			
			if (node.motion.acceleration.x < 0) {
				node.spatial.scaleX = -1;
			}
			else if (node.motion.acceleration.x > 0) {
				node.spatial.scaleX = 1;
			}
			clip.rotation = Math.abs(node.motion.velocity.x/50);
			waveTime += 0.05;
			node.motion.velocity.y += 10*Math.sin(waveTime);
			
			var legLeft:MovieClip = clip.legLeft;
			var legRight:MovieClip = clip.legRight;
			/*if (Math.abs(node.motion.acceleration.x/4) > 200) {
				legPush += (2 - legPush)/20;
			}
			else {
				legPush += -legPush/20;
			}*/
			legPush = Math.min( 2, Math.abs(node.motion.velocity.x/100) );
			legAcceleration = -legLeft.rotation/20 + legPush;
			legVelocity += legAcceleration;
			legVelocity *= legDamp;
			legLeft.rotation += legVelocity;
			legRight.rotation += legVelocity*1.5;
			//shinRotation += (legLeft.rotation - shinRotation)/12;
			//footRotation += (shinRotation - footRotation)/12;
			//legLeft.shin.rotation = -legLeft.rotation + shinRotation;
			//legLeft.shin.foot.rotation = -legLeft.rotation - legLeft.shin.rotation + footRotation;
			
			checkFrame(node);
			checkCages(node);
		}
		
		private function checkFrame( node:PuppetMonsterNode ):void
		{
			var body:MovieClip = (node.display.displayObject as MovieClip);
			var headEntity:Entity = (EntityUtils.getChildById(node.entity, "head"));
			var headTimeline:Timeline = headEntity.get(Timeline);
			
			switch(body.currentFrameLabel)
			{
				case "float":
				{
					headTimeline.gotoAndPlay("laugh");
					break;
				}
				case "floatLoop":
				{
					if (!flashing && !entering) {
						node.timeline.gotoAndPlay("float");
					}
					break;
				}
				case "flashStart":
				{
					headTimeline.gotoAndPlay("flash");
					break;
				}
				case "flashLoop":
				{
					if (flashing && !entering && !leaving) {
						node.timeline.gotoAndPlay("flash");
					}
					break;
				}
				case "enterComplete":
				{
					entering = false;
					break;
				}
				case "leaveComplete":
				{
					node.timeline.playing = false;
					break;
				}
				case "hideLegs":
				{
					body.legLeft.visible = false;
					body.legRight.visible = false;
					break;
				}
				case "showLegs":
				{
					body.legLeft.visible = true;
					body.legRight.visible = true;
					break;
				}
					
				default:
				{
					break;
				}
			}
			
			switch(body.head.currentFrameLabel)
			{
				case "laughLoop":
				{
					headTimeline.gotoAndPlay("laugh");
					break;
				}
				case "flashEnd":
				{
					headTimeline.stop();
					break;
				}
					
				default:
				{
					break;
				}
			}
		}
		
		private function checkCages( node:PuppetMonsterNode ):void
		{
			//currentCage = null;
			var minDistance:Number = 500;
			for (var i:uint=0; i<node.puppetMonster.cageEntities.length; i++) {
				var cage:Entity = node.puppetMonster.cageEntities[i];
				var pt1:Point = new Point(cage.get(Spatial).x, cage.get(Spatial).y);
				var pt2:Point = new Point(super.group.shellApi.player.get(Spatial).x, super.group.shellApi.player.get(Spatial).y);
				var d:Number = Point.distance(pt1, pt2);
				var dy:Number = Math.abs(pt1.y - pt2.y);
				if (d < minDistance && dy < 200) {
					minDistance = d;
					currentCage = cage; //We want the currentCage to be the one closest to the player. The monster will enter or leave through this cage.
					if (!currentExitCage) {
						currentExitCage = cage;
					}
				}
			}
		}
	}
}