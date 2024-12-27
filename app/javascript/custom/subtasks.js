document.addEventListener('DOMContentLoaded', () => {
  const addSubtaskBtn = document.getElementById('add-subtask-btn');
  const subtaskPopup = document.getElementById('subtask-popup');
  const overlay = document.getElementById('overlay');
  const closePopup = document.getElementById('close-popup');

  const togglePopupVisibility = (isVisible) => {
    const displayValue = isVisible ? 'block' : 'none';
    subtaskPopup.style.display = displayValue;
    overlay.style.display = displayValue;
  };

  addSubtaskBtn.addEventListener('click', () => togglePopupVisibility(true));
  closePopup.addEventListener('click', () => togglePopupVisibility(false));
  overlay.addEventListener('click', () => togglePopupVisibility(false));
});
