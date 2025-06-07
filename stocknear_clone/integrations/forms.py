import keyring
from django import forms
from .models import Integration

class IntegrationForm(forms.ModelForm):
    password = forms.CharField(
        widget=forms.PasswordInput(render_value=True),
        required=True,
        help_text="API key or password"
    )

    class Meta:
        model = Integration
        fields = ['provider', 'username']

    def __init__(self, *args, **kwargs):
        # Pop initial password from keychain if existing
        super().__init__(*args, **kwargs)
        if self.instance.pk:
            pw = keyring.get_password(self.instance.provider, self.instance.username)
            self.fields['password'].initial = pw

    def save(self, commit=True):
        inst = super().save(commit=False)
        # generate key_name as provider:username
        key_name = f"{inst.provider}:{inst.username}"
        inst.key_name = key_name
        if commit:
            inst.save()
            keyring.set_password(inst.provider, inst.username, self.cleaned_data['password'])
        return inst
