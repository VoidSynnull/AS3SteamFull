package game.ui.characterDialog
{
	import game.data.scene.characterDialog.DialogData;

	public interface DialogTriggerDelegate
	{
		function handleDialogTriggerEvent(dialogData:DialogData):void
	}
}