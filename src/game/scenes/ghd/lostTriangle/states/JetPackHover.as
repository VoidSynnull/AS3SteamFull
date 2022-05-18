package game.scenes.ghd.lostTriangle.states
{
	import game.data.animation.entity.character.SoarDown;
	import game.util.SkinUtils;

	public class JetPackHover extends JetPackState
	{
		public function JetPackHover()
		{
			super.type = JetPackState.HOVER;
		}
		
		override public function start():void
		{
			node.jetpackHealth.hurting = false;
			SkinUtils.setEyeStates( node.entity, "squint" );
			setAnim( SoarDown );
		}
	}
}