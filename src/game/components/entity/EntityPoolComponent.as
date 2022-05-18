package game.components.entity
{
	import ash.core.Component;
	
	import game.managers.EntityPool;

	public class EntityPoolComponent extends Component
	{
		public function EntityPoolComponent( entityPool = null )
		{
			this.pool = entityPool;
		}
		
		public var pool:EntityPool;
		
		override public function destroy():void
		{
			// NOTE :: Not sure we necessarily want to do this, but serves as a safety measure for now. - bard
			if( this.pool != null )
			{
				this.pool.destroy();	
				this.pool = null;
			}
			super.destroy();
		}
	}
}