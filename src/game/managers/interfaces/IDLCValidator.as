package game.managers.interfaces
{
	import game.data.dlc.DLCContentData;

	public interface IDLCValidator
	{
		/**
		 * Determines if content asscociated with DLCContentData is valid.
		 * Validity testing may vary, but method should set call DLCManager.setContentValid before completeing
		 * @param dlcContent - DLCContentData to be tested
		 * @param onComplete - called when validation is complete, will return dlcContent with it's inValid flag set appropriately
		 */
		function validateContent( dlcContent:DLCContentData, onComplete:Function ):void
	}
}