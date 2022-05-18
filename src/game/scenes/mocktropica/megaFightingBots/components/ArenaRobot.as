package game.scenes.mocktropica.megaFightingBots.components
{
	import com.greensock.TimelineMax;
	import com.greensock.TweenLite;
	
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.data.TimedEvent;
	import game.scenes.mocktropica.megaFightingBots.particles.DustParticles;
	
	public class ArenaRobot extends Component
	{
		public function ArenaRobot($startGridIndex:Point, $hitPoints:int = 100, $energyPoints:int = 110, $speed:Number = 0.5, $strength:Number = 1)
		{
			moveCoord = $startGridIndex;
			path = [[moveCoord.y, moveCoord.x]];
			startPoint = moveCoord;
			hitPoints = maxHitPoints = $hitPoints;
			energyPoints = maxEnergyPoints = $energyPoints;
			speed = $speed;
			strength = $strength;
		}
		
		public function newRobotStage($stage:int):void{
			if(!easyMode){
				maxHitPoints = hitPoints = this["stage"+$stage+"Robot"].hitPoints * 0.75;
			} else {
				maxHitPoints = hitPoints = this["stage"+$stage+"Robot"].hitPoints * 0.3;
			}
			maxEnergyPoints = energyPoints = this["stage"+$stage+"Robot"].energyPoints * 0.6;
			speed = this["stage"+$stage+"Robot"].speed;
			strength = this["stage"+$stage+"Robot"].strength * 0.6;
			aggression = this["stage"+$stage+"Robot"].aggression;
			
			body = $stage + 1;
			arms = $stage + 1;
			legs = $stage + 1;
		}
		
		public var stage1Robot:Object = {hitPoints:150, energyPoints:120, speed:0.5, strength:1, aggression:0};
		public var stage2Robot:Object = {hitPoints:160, energyPoints:130, speed:0.5, strength:1, aggression:0.2};
		public var stage3Robot:Object = {hitPoints:170, energyPoints:130, speed:0.4, strength:1.2, aggression:0.4};
		public var stage4Robot:Object = {hitPoints:180, energyPoints:140, speed:0.4, strength:1.2, aggression:0.4};
		public var stage5Robot:Object = {hitPoints:200, energyPoints:150, speed:0.4, strength:1.4, aggression:0.6};
		
		public var moveCoord:Point; // 2D index Point on grid - for movement only
		public var hitCoord:Point; // 2D index Point on grid - the approximent "hit" coordinate of the square of this robot (used in hit detection)
		
		public var path:Array; // 2d array of points in reverse order - per billy's pathfinding code
		
		public var maxHitPoints:Number; // max life of robot
		public var hitPoints:Number; // life of robot
		
		public var maxEnergyPoints:Number; // max energy of robot
		public var energyPoints:Number; // energy of robot
		
		public var speed:Number; // speed of how fast robot completes a grid move
		public var strength:Number; // damage multiplier for taking a hit from this robot (only effects normal hits, not wall hits)
		public var aggression:Number; // chance modifier on whether the robot will persue the player on it's next move cycle.
		
		public var lost:Boolean = false;
		public var win:Boolean = false;
		
		public var wins:int = 0;
		public var moveTween:TweenLite;
		public var colorTimeline:TimelineMax;
		
		public var moving:Boolean = false;
		public var charging:Boolean = false;
		public var stunned:Boolean = false; // can occur either when hit, or charging
		public var stunTimerEvent:TimedEvent;
		
		public var energyExhausted:Boolean = false;
		
		public var atDestination:Boolean = true;
		
		public var currentFaceDir:String = null; // direction of face
		public var chargeDir:String = null; // direction of charge - also is a trigger in RobotSystem
		public var knockDir:String = null; // direction of knockback - also is a trigger in RobotSystem
		public var savedDir:String = null; // last direction of charge (used in knockBack dir of hit targets)
		
		public var dustEmitter:DustParticles;
		public var dustEntity:Entity;
		
		public var playerRobot:Boolean = false;
		
		public var frontEntity:Entity; // front facing entity containing the movieclip and timeline components
		public var backEntity:Entity; // back facing entity containing the movieclip and timeline components
		public var leftEntity:Entity; // left facing entity containing the movieclip and timeline components
		public var rightEntity:Entity; // right facing entity containing the movieclip and timeline components
		
		public var currentFaceEntity:Entity;
		public var initted:Boolean = false;
		public var currentAnimation:String = "idle";
		
		public var startPoint:Point;
		public var freeze:Boolean = true;
		
		public var easyMode:Boolean = false;
		
		// look config 
		public var body:int = 1;
		public var legs:int = 1;
		public var arms:int = 1;
		public var mood:int = 1;
	}
}