package game.scenes.custom.StarShooterSystem
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import game.components.timeline.Timeline;
	import game.util.DataUtils;
	
	public class EnemyAi extends Component
	{
		public var face:String = NONE;
		public var projectileSpeed:Number = 400;
		public var offset:Number = 50;
		public var health:int = 1;
		public var currentHealth:int = 1;
		public var points:Number = 100;
		// used to either track player or last location to determine rotation
		public var p2:Point;
		// can change to something else so specific enemies 
		// fire at specific times according to a patern
		public var fireCommand:String = "fire";
		public var type:String;
		public var ammoType:String = "ammo";
		public var active:Boolean = false;
		public var fire:Boolean = false;
		
		public function EnemyAi(xml:XML = null):void
		{
			if(xml)
			{
				type = DataUtils.getString(xml.attribute("id")[0]);
				
				points = DataUtils.getNumber(xml.attribute("points")[0]);
				
				if(xml.hasOwnProperty("@ammoType"))
					ammoType = DataUtils.getString(xml.attribute("ammoType")[0]);
				
				if(xml.hasOwnProperty("@face"))
					face = DataUtils.getString(xml.attribute("face")[0]);
				
				if(xml.hasOwnProperty("@health"))
					health = DataUtils.getNumber(xml.attribute("health")[0]);
				
				currentHealth = health;
				
				if(xml.hasOwnProperty("@projectileSpeed"))
					projectileSpeed = DataUtils.getNumber(xml.attribute("projectileSpeed")[0]);
			}
		}
		
		public function duplicate():EnemyAi
		{
			var enemy:EnemyAi = new EnemyAi();
			enemy.type = type;
			enemy.points = points;
			enemy.health = enemy.currentHealth = health;
			enemy.face = face;
			enemy.projectileSpeed = projectileSpeed;
			return enemy;
		}
		
		public function commandFire(command:String, timeline:Timeline):void
		{
			if(!active)
				return;
			var target:String = command;
			var index:int = command.indexOf("reverse");
			if(index > 0)
			{
				target = command.substr(0,index);
			}
			if(target.indexOf(fireCommand)>=0 || fireCommand.indexOf(target) >= 0)
			{
				// when facing forward only fire if the command
				// is the same direction you are moving.
				// not having reverse is assumed to be forwards
				if(face == FORWARD)
				{
					if((index > 0) == timeline.reverse)
					{
						fire = true;
					}
				}
				else
				{
					fire = true;
				}
			}
		}
		
		// dont change orientation
		public static const NONE:String = "none";
		// face where you are moving
		public static const FORWARD:String = "forward";
		// always face the player
		public static const PLAYER:String = "player";
	}
}