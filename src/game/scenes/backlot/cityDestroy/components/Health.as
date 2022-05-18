package game.scenes.backlot.cityDestroy.components
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	
	import org.osflash.signals.Signal;
	
	public class Health extends Component
	{
		public var health:Number;
		public var maxHealth:Number;
		public var healthBar:Entity;
		public var healthScale:Point;
		public var died:Signal;
		public var dead:Boolean;
		public var horizontal:Boolean;
		
		public function Health(maxHealth:Number = 1, healthBar:Entity = null, horizontal:Boolean = true, healthScale:Point = null)
		{
			this.maxHealth = maxHealth;
			health = this.maxHealth;
			this.healthBar = healthBar;
			this.horizontal = horizontal;
			this.healthScale = healthScale;
			
			if(this.healthScale == null)
				this.healthScale = new Point(1,1);
			
			if(this.healthBar != null)
			{
				Display(this.healthBar.get(Display)).displayObject.scaleX = this.healthScale.x;
				Display(this.healthBar.get(Display)).displayObject.scaleY = this.healthScale.y;
			}
			
			dead = false;
			died = new Signal();
		}
	}
}